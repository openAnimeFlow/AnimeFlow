import 'dart:async';
import 'dart:io';

import 'flow_secure_socket.dart';

typedef FlowSocketDial = Future<ConnectionTask<Socket>> Function(
    String host, int port);
typedef FlowRawSocketDial = Future<ConnectionTask<RawSocket>> Function(
    String host, int port);

class FlowConnectionCancelled implements Exception {
  const FlowConnectionCancelled();
}

/// Each fetch has its own cancellation scope, including DNS/TCP/TLS acquisition.
class FlowConnectionContext {
  FlowConnectionContext({this.budget = const Duration(seconds: 8)});

  static final zoneKey = Object();
  static FlowConnectionContext? get current =>
      Zone.current[zoneKey] as FlowConnectionContext?;

  final Duration budget;
  final Set<void Function()> _cancellations = {};
  bool cancelled = false;

  void add(void Function() cancel) {
    if (cancelled) {
      cancel();
    } else {
      _cancellations.add(cancel);
    }
  }

  void remove(void Function() cancel) => _cancellations.remove(cancel);

  void cancel() {
    cancelled = true;
    for (final cancel in _cancellations.toList()) {
      cancel();
    }
    _cancellations.clear();
  }
}

/// Returns TLS sockets for HTTPS; HttpClient does not add TLS to a custom factory.
class FlowConnectionConnector {
  FlowConnectionConnector({
    required this.endpoint,
    this.addresses = const [],
    this.allowDnsFallback = true,
    this.candidateTimeout = const Duration(milliseconds: 1500),
    this.dnsReserve = const Duration(seconds: 3),
    this.securityContext,
    this.onAddressFailure,
    this.isAddressAvailable,
    FlowSocketDial? dial,
    FlowRawSocketDial? rawDial,
  })  : _dial = dial ?? ((host, port) => Socket.startConnect(host, port)),
        _rawDial =
            rawDial ?? ((host, port) => RawSocket.startConnect(host, port));

  final Uri endpoint;
  final List<String> addresses;
  final bool allowDnsFallback;
  final Duration candidateTimeout;
  final Duration dnsReserve;
  final SecurityContext? securityContext;
  final void Function(String address)? onAddressFailure;
  final bool Function(String address)? isAddressAvailable;
  final FlowSocketDial _dial;
  final FlowRawSocketDial _rawDial;

  bool matches(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == endpoint.host &&
      uri.port == endpoint.port;

  HttpClient createClient() => HttpClient(context: securityContext)
    ..idleTimeout = const Duration(seconds: 15)
    ..connectionFactory = connect;

  Future<ConnectionTask<Socket>> connect(
      Uri uri, String? proxyHost, int? proxyPort) async {
    final context = FlowConnectionContext.current;
    final budget = context?.budget ?? const Duration(seconds: 8);
    final isTarget = matches(uri) && proxyHost == null;
    final targets = <String?>[
      if (isTarget)
        ...addresses.where((ip) => isAddressAvailable?.call(ip) ?? true),
      if (!isTarget || allowDnsFallback || addresses.isEmpty) null,
    ];
    final result = Completer<Socket>();
    // Cancellation can precede HttpClient attaching to the returned task.
    unawaited(result.future.then<void>((_) {}, onError: (_) {}));
    final watch = Stopwatch()..start();
    _SocketAttempt? active;
    var ended = false;
    late final Timer timer;

    void stop([Object error = const FlowConnectionCancelled()]) {
      if (ended) return;
      ended = true;
      active?.cancel();
      timer.cancel();
      if (!result.isCompleted) result.completeError(error);
    }

    void cancel() => stop();
    timer = Timer(
        budget, () => stop(const SocketException('Flow connection timed out')));
    context?.add(cancel);

    Future<void> run() async {
      Object lastError = const SocketException('No available Flow endpoint');
      try {
        for (final address in targets) {
          if (ended) return;
          final remaining = budget - watch.elapsed;
          if (remaining <= Duration.zero) break;
          // Short requests reserve their entire budget for DNS.
          if (address != null && allowDnsFallback && remaining <= dnsReserve) {
            continue;
          }
          var timeout = address == null ? remaining : candidateTimeout;
          if (address != null && allowDnsFallback) {
            final available = remaining - dnsReserve;
            if (available < timeout) timeout = available;
          }
          if (remaining < timeout) timeout = remaining;
          final attempt = _SocketAttempt(
            dial: _dial,
            rawDial: _rawDial,
            host: proxyHost ?? address ?? uri.host,
            port: proxyPort ?? uri.port,
            tlsHost:
                proxyHost == null && uri.scheme == 'https' ? uri.host : null,
            securityContext: securityContext,
          );
          active = attempt;
          try {
            final socket = await attempt.open().timeout(timeout);
            if (ended) {
              socket.destroy();
              return;
            }
            ended = true;
            timer.cancel();
            result.complete(socket);
            return;
          } catch (error) {
            attempt.cancel();
            if (ended) return;
            lastError = error is TimeoutException
                ? const SocketException('Flow endpoint timed out')
                : error;
            if (address != null) onAddressFailure?.call(address);
          }
        }
        if (!ended) stop(lastError);
      } catch (error) {
        stop(error);
      } finally {
        context?.remove(cancel);
        timer.cancel();
      }
    }

    // Install error handling before any asynchronous dial can finish.
    unawaited(run());
    return ConnectionTask.fromSocket(result.future, cancel);
  }
}

class _SocketAttempt {
  _SocketAttempt(
      {required this.dial,
      required this.rawDial,
      required this.host,
      required this.port,
      required this.tlsHost,
      required this.securityContext});

  final FlowSocketDial dial;
  final FlowRawSocketDial rawDial;
  final String host;
  final int port;
  final String? tlsHost;
  final SecurityContext? securityContext;
  ConnectionTask<Socket>? _task;
  ConnectionTask<RawSocket>? _rawTask;
  RawSocket? _rawSocket;
  Socket? _socket;
  bool _cancelled = false;

  Future<Socket> open() async {
    if (tlsHost != null) return _openTls();
    final task = _task = await dial(host, port);
    // startConnect itself may return after cancellation (e.g. slow DNS).
    if (_cancelled) {
      task.cancel();
      unawaited(task.socket.then<void>((s) => s.destroy(), onError: (_) {}));
      throw const FlowConnectionCancelled();
    }
    var socket = _socket = await task.socket;
    if (_cancelled) {
      socket.destroy();
      throw const FlowConnectionCancelled();
    }
    if (_cancelled) {
      socket.destroy();
      throw const FlowConnectionCancelled();
    }
    return socket;
  }

  Future<Socket> _openTls() async {
    final task = _rawTask = await rawDial(host, port);
    if (_cancelled) {
      task.cancel();
      unawaited(task.socket.then<void>((raw) {
        unawaited(raw.close());
      }, onError: (_) {}));
      throw const FlowConnectionCancelled();
    }
    final raw = _rawSocket = await task.socket;
    if (_cancelled) {
      unawaited(raw.close());
      throw const FlowConnectionCancelled();
    }
    final secure = await RawSecureSocket.secure(raw,
        host: tlsHost,
        context: securityContext,
        supportedProtocols: const ['http/1.1']);
    if (_cancelled) {
      unawaited(secure.close());
      throw const FlowConnectionCancelled();
    }
    return _socket = FlowSecureSocket(secure);
  }

  void cancel() {
    _cancelled = true;
    _task?.cancel();
    _rawTask?.cancel();
    final raw = _rawSocket;
    if (raw != null) unawaited(raw.close());
    _socket?.destroy();
  }
}

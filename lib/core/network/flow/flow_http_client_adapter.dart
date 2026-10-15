import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'flow_connection_connector.dart';
import 'flow_endpoint_pool.dart';

/// A stable Dio adapter whose old pools drain while new fetches use new routes.
class FlowHttpClientAdapter implements HttpClientAdapter {
  FlowHttpClientAdapter(
      {required this.pool,
      HttpClientAdapter Function(List<String>, int)? createAdapter})
      : _createAdapter = createAdapter {
    pool.addListener(_routeChanged);
  }

  final FlowEndpointPool pool;
  final HttpClientAdapter Function(List<String>, int)? _createAdapter;
  final Set<_AdapterGeneration> _retired = {};
  final Set<FlowConnectionContext> _contexts = {};
  _AdapterGeneration? _current;
  bool _closed = false;

  _AdapterGeneration _generation() => _current ??= _AdapterGeneration(
        _createAdapter?.call(pool.preferredAddresses, pool.networkGeneration) ??
            IOHttpClientAdapter(
                createHttpClient: FlowConnectionConnector(
              endpoint: pool.endpoint,
              addresses: List.of(pool.preferredAddresses),
              isAddressAvailable: pool.isAddressAvailable,
              onAddressFailure: _failureCallback(pool.networkGeneration),
            ).createClient),
      );

  void Function(String) _failureCallback(int generation) =>
      (address) => pool.reportConnectionFailure(address, generation);

  void _routeChanged() {
    final old = _current;
    _current = null;
    if (old != null) {
      old.retired = true;
      _retired.add(old);
      _drain(old);
    }
  }

  void _drain(_AdapterGeneration generation) {
    if (!generation.retired || generation.pending != 0) return;
    if (!generation.closed) {
      generation.closed = true;
      generation.adapter.close();
    }
    if (generation.streams == 0) _retired.remove(generation);
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (_closed) throw StateError('Flow adapter is closed');
    pool.expireRoute();
    final generation = _generation();
    var budget = const Duration(seconds: 8);
    final requested = options.connectTimeout;
    if (requested != null && requested > Duration.zero && requested < budget) {
      budget = requested;
    }
    final context = FlowConnectionContext(budget: budget);
    _contexts.add(context);
    final weakContext = WeakReference(context);
    unawaited(cancelFuture?.then<void>((_) => weakContext.target?.cancel(),
        onError: (_) => weakContext.target?.cancel()));
    generation.pending++;
    try {
      final body = await runZoned(
        () => generation.adapter.fetch(options, requestStream, cancelFuture),
        zoneValues: {FlowConnectionContext.zoneKey: context},
      );
      generation.streams++;
      body.stream = _track(body.stream, generation);
      return body;
    } catch (error) {
      if (context.cancelled) {
        throw DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            message: '请求已取消');
      }
      if (_isConnectionFailure(error) &&
          options.uri.host == pool.endpoint.host) {
        pool.requestRevalidation();
      }
      rethrow;
    } finally {
      // Also abort acquisition if IOHttpClientAdapter timed out before it ended.
      context.cancel();
      _contexts.remove(context);
      generation.pending--;
      _drain(generation);
    }
  }

  bool _isConnectionFailure(Object error) =>
      error is SocketException ||
      error is HandshakeException ||
      error is TimeoutException ||
      error is DioException &&
          const {
            DioExceptionType.connectionError,
            DioExceptionType.connectionTimeout,
            DioExceptionType.receiveTimeout,
            DioExceptionType.sendTimeout,
            DioExceptionType.badCertificate,
          }.contains(error.type);

  Stream<Uint8List> _track(
      Stream<Uint8List> source, _AdapterGeneration generation) async* {
    try {
      yield* source;
    } finally {
      generation.streams--;
      _drain(generation);
    }
  }

  @override
  void close({bool force = false}) {
    if (!_closed) {
      _closed = true;
      pool.removeListener(_routeChanged);
      _routeChanged();
    }
    if (force) {
      for (final context in _contexts.toList()) {
        context.cancel();
      }
      for (final generation in _retired.toList()) {
        generation.adapter.close(force: true);
        generation.closed = true;
      }
    }
  }
}

class _AdapterGeneration {
  _AdapterGeneration(this.adapter);
  final HttpClientAdapter adapter;
  int pending = 0;
  int streams = 0;
  bool retired = false;
  bool closed = false;
}

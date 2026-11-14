import 'dart:async';
import 'dart:io';

import 'flow_connection_scope.dart';
import 'flow_socket_dialer.dart';

/// 传输层对“把主机名换成候选 IP”的唯一依赖：一个解析回调。
///
/// 之所以是函数类型而不是抽象类：这里只需要一个方法、一个实现（Cloudflare
/// DoH），函数签名已能完整表达契约，且同样切断了传输层对具体解析器的依赖。
/// 若将来出现第二个实现、或多出 `close` / 缓存失效等生命周期方法，
/// 再升级为抽象类即可，调用方的语义不变。
///
/// 失败时返回空列表，不要抛异常——建连流程会把它当作“本轮无解析结果”。
typedef FlowHostResolve = Future<List<String>> Function(String host);

/// 传输层的“固定对端建连”能力：把一条 HTTPS 客户端固定到指定的 IP 集合。
///
/// 这是原先写在 `FlowConnectionConnector` 里的全部底层逻辑：
/// 逐个候选地址拨号 → 失败回退 DoH 解析结果 → 最后回退系统 DNS，
/// 全过程受 [FlowConnectionContext] 的预算与取消控制。
///
/// 该模块不认识任何具体解析器，只认 [FlowHostResolve] 回调；
/// connector 传入 `dohResolver.resolve`，DoH 解析器则传入 `null`（自己建连），
class FlowPinnedConnection {
  FlowPinnedConnection({
    required this.endpoint,
    this.addresses = const [],
    this.allowDnsFallback = true,
    this.candidateTimeout = const Duration(milliseconds: 1500),
    this.securityContext,
    this.resolver,
    this.onAddressFailure,
    this.isAddressAvailable,
  });

  /// 目标端点，用于判断某个请求是否属于本连接器、并作为 TLS/SNI 名称。
  final Uri endpoint;

  /// 优先拨号的候选 IP 列表，顺序即尝试顺序。
  final List<String> addresses;

  /// 候选 IP 全部失败后是否允许回退系统 DNS（`addresses` 为空时总会回退）。
  final bool allowDnsFallback;

  /// 单个候选 IP 的建连预算，避免一个坏 IP 吃掉整个请求预算。
  final Duration candidateTimeout;

  /// 连接时限较短时，为 DNS 路径预留的时间。
  static const dnsReserve = Duration(seconds: 3);

  final SecurityContext? securityContext;

  /// 可选的主机名解析回调（通常是 Cloudflare DoH），为空时只走候选 IP 与系统 DNS。
  final FlowHostResolve? resolver;

  /// 候选地址建连失败的回调，调用方据此维护冷却与路由。
  final void Function(String address)? onAddressFailure;

  /// 候选地址当前是否可用，返回 false 的地址会被跳过。
  final bool Function(String address)? isAddressAvailable;

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
    // 取消操作可能发生在 HttpClient 开始监听返回的连接任务之前。
    unawaited(result.future.then<void>((_) {}, onError: (_) {}));
    final watch = Stopwatch()..start();
    FlowSocketDialer? active;
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
        Future<bool> tryAddress(String? address,
            {bool reserveForDnsFallback = true}) async {
          if (ended) return false;
          final remaining = budget - watch.elapsed;
          if (remaining <= Duration.zero) return false;
          // 连接时限较短时，将全部剩余时间留给 DNS 路径。
          if (address != null &&
              allowDnsFallback &&
              reserveForDnsFallback &&
              remaining <= dnsReserve) {
            return false;
          }
          var timeout = address == null ? remaining : candidateTimeout;
          if (address != null && allowDnsFallback && reserveForDnsFallback) {
            final available = remaining - dnsReserve;
            if (available < timeout) timeout = available;
          }
          if (remaining < timeout) timeout = remaining;
          final attempt = FlowSocketDialer(
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
              return false;
            }
            ended = true;
            timer.cancel();
            result.complete(socket);
            return true;
          } catch (error) {
            attempt.cancel();
            if (ended) return false;
            lastError = error is TimeoutException
                ? const SocketException('Flow endpoint timed out')
                : error;
            if (address != null) onAddressFailure?.call(address);
          }
          return false;
        }

        for (final address in targets.whereType<String>()) {
          if (await tryAddress(address)) return;
        }
        final hostResolver = resolver;
        if (isTarget && allowDnsFallback && hostResolver != null && !ended) {
          try {
            final resolved =
                await hostResolver(uri.host).timeout(budget - watch.elapsed);
            for (final address in resolved) {
              if (ended) return;
              if (await tryAddress(address, reserveForDnsFallback: false)) {
                return;
              }
            }
          } on Object catch (error) {
            if (ended) return;
            lastError = error;
          }
        }
        if (targets.contains(null) && !ended) await tryAddress(null);
        if (!ended) stop(lastError);
      } catch (error) {
        stop(error);
      } finally {
        context?.remove(cancel);
        timer.cancel();
      }
    }

    // 在异步建连可能完成之前注册错误处理。
    unawaited(run());
    return ConnectionTask.fromSocket(result.future, cancel);
  }
}

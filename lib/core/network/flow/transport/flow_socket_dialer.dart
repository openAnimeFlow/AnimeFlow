import 'dart:async';
import 'dart:io';

import 'flow_connection_scope.dart';
import 'flow_secure_socket.dart';

/// 面向上游某一个对端地址的单次拨号：TCP 建连，必要时完成 TLS 握手。
///
/// 这个类只负责“把一条连接打开”，不决定拨哪个地址、按什么顺序拨、
/// 失败后如何回退——那些属于上层策略。它唯一的额外职责是可取消：
/// 调用方随时可以 `cancel()`，已占用的 TCP/TLS 句柄会被立即释放。
///
/// 之所以把 TLS 放在这里而不是交给 HttpClient：自定义 connectionFactory
/// 返回的套接字已经是“可用字节流”，HttpClient 不会补做握手。
class FlowSocketDialer {
  FlowSocketDialer({
    required this.host,
    required this.port,
    this.tlsHost,
    this.securityContext,
  });

  /// 实际拨号的地址或主机名。
  final String host;
  final int port;

  /// 非空表示需要在当前连接上完成 TLS 握手，并用该名称校验证书。
  ///
  /// 当 [host] 是固定 IP 时，这里通常是原始域名，避免证书校验失败。
  final String? tlsHost;
  final SecurityContext? securityContext;

  ConnectionTask<Socket>? _task;
  ConnectionTask<RawSocket>? _rawTask;
  RawSocket? _rawSocket;
  Socket? _socket;
  bool _cancelled = false;

  bool get cancelled => _cancelled;

  /// 打开连接；取消、握手失败或被上层超时打断时抛出异常。
  Future<Socket> open() async {
    if (tlsHost != null) return _openTls();
    final task = _task = await Socket.startConnect(host, port);
    // startConnect 本身可能在取消后才返回，例如 DNS 解析较慢时。
    if (_cancelled) {
      task.cancel();
      unawaited(task.socket.then<void>((s) => s.destroy(), onError: (_) {}));
      throw const FlowConnectionCancelled();
    }
    final socket = _socket = await task.socket;
    if (_cancelled) {
      socket.destroy();
      throw const FlowConnectionCancelled();
    }
    return socket;
  }

  Future<Socket> _openTls() async {
    final task = _rawTask = await RawSocket.startConnect(host, port);
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

import 'dart:async';

/// 建连过程被所属请求取消时抛出的信号异常。
///
/// 该异常不携带任何策略语义，仅表示“调用方已不再需要这条连接”，
/// 使上层可以把它映射成各自的取消类型（例如 DioExceptionType.cancel）。
class FlowConnectionCancelled implements Exception {
  const FlowConnectionCancelled();

  @override
  String toString() => 'FlowConnectionCancelled';
}

/// 每个请求拥有独立的取消范围，覆盖 DNS 解析、TCP 建连和 TLS 握手。
///
/// 传输层只读取当前 Zone 中的实例，不关心它由谁创建：
/// Dio 适配器、探测器和解析器都可以各自建立作用域。
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

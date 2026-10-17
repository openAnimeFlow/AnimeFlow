import 'dart:async';

/// 独立于平台 API 的尾沿防抖调度器，同一时间仅运行一轮探测。
class FlowProbeScheduler {
  FlowProbeScheduler({
    required Future<void> Function() run,
    required void Function() cancel,
    bool Function()? shouldRun,
    DateTime Function()? now,
    void Function(Object)? onError,
    Duration initialDelay = Duration.zero,
  })  : _run = run,
        _cancel = cancel,
        _shouldRun = shouldRun ?? (() => true),
        _now = now ?? DateTime.now,
        _onError = onError ?? ((_) {}) {
    // 宽限期独立于尾沿防抖，网络通知不会提前结束或重新计时。
    if (initialDelay > Duration.zero) {
      _startupTimer = Timer(initialDelay, () {
        if (!(_timer?.isActive ?? false)) unawaited(_flush(_ticket));
      });
    }
  }

  final Future<void> Function() _run;
  final void Function() _cancel;
  final bool Function() _shouldRun;
  final DateTime Function() _now;
  final void Function(Object) _onError;
  static const _debounce = Duration(seconds: 2);
  static const _minimumInterval = Duration(minutes: 5);
  Timer? _startupTimer;
  Timer? _timer;
  Future<void>? _running;
  DateTime? _lastRun;
  int _generation = 0;
  int _runningGeneration = -1;
  int _ticket = 0;
  bool _active = true;
  bool _online = true;
  bool _force = false;
  bool _pending = false;
  bool _disposed = false;

  void request({bool force = false}) {
    if (_disposed) return;
    if (_running != null && _runningGeneration == _generation) return;
    _pending = true;
    _force = _force || force;
    _timer?.cancel();
    final ticket = ++_ticket;
    if (_active && _online) {
      _timer = Timer(_debounce, () => unawaited(_flush(ticket)));
    }
  }

  void networkChanged({required bool online}) {
    if (_disposed) return;
    _generation++;
    _online = online;
    _cancel();
    request(force: true);
  }

  void setActive(bool active) {
    if (_disposed || active == _active) return;
    _active = active;
    if (!active) {
      _timer?.cancel();
      _ticket++;
      if (_running != null) {
        _cancel();
        _pending = true;
        _force = true;
        _generation++;
      }
    } else {
      request(force: _pending && _force);
    }
  }

  Future<void> _flush(int ticket) async {
    // 网络切换可能已取消上一轮探测，此处等待其完成套接字清理。
    await _running;
    if (_disposed ||
        ticket != _ticket ||
        !_active ||
        !_online ||
        !_pending ||
        (_startupTimer?.isActive ?? false)) {
      return;
    }
    // 统一在执行入口判断需求，跳过探测不消耗测速间隔。
    if (!_shouldRun()) {
      _pending = false;
      _force = false;
      return;
    }
    if (!_force &&
        _lastRun != null &&
        _now().difference(_lastRun!) < _minimumInterval) {
      _pending = false;
      return;
    }
    _pending = false;
    _force = false;
    _lastRun = _now();
    _runningGeneration = _generation;
    final operation = _runSafely();
    _running = operation;
    await operation;
    if (identical(_running, operation)) _running = null;
  }

  Future<void> _runSafely() async {
    try {
      await _run();
    } catch (error) {
      _onError(error);
    }
  }

  void dispose() {
    _disposed = true;
    _startupTimer?.cancel();
    _timer?.cancel();
    _ticket++;
    _cancel();
  }
}

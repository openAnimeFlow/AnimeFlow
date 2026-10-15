import 'dart:async';

/// Trailing debounce and single-flight scheduling, independent of platform APIs.
class FlowProbeScheduler {
  FlowProbeScheduler({
    required Future<void> Function() run,
    required void Function() cancel,
    DateTime Function()? now,
    void Function(Object)? onError,
    this.debounce = const Duration(seconds: 2),
    this.minimumInterval = const Duration(minutes: 5),
  })  : _run = run,
        _cancel = cancel,
        _now = now ?? DateTime.now,
        _onError = onError ?? ((_) {});

  final Future<void> Function() _run;
  final void Function() _cancel;
  final DateTime Function() _now;
  final void Function(Object) _onError;
  final Duration debounce;
  final Duration minimumInterval;
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
      _timer = Timer(debounce, () => unawaited(_flush(ticket)));
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
    // A network switch may have cancelled an old round still releasing sockets.
    await _running;
    if (_disposed || ticket != _ticket || !_active || !_online || !_pending) {
      return;
    }
    if (!_force &&
        _lastRun != null &&
        _now().difference(_lastRun!) < minimumInterval) {
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
    _timer?.cancel();
    _ticket++;
    _cancel();
  }
}

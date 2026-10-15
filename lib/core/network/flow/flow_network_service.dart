import 'dart:async';

import 'package:anime_flow/core/logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'flow_endpoint_pool.dart';
import 'flow_probe_scheduler.dart';

class FlowNetworkService with WidgetsBindingObserver {
  FlowNetworkService(
      {FlowEndpointPool? pool,
      Connectivity? connectivity,
      Stream<List<ConnectivityResult>>? networkChanges,
      Future<List<ConnectivityResult>> Function()? readConnectivity})
      : _pool = pool ?? FlowEndpointPool.instance,
        _connectivity = connectivity ?? Connectivity(),
        _networkChangesOverride = networkChanges,
        _readConnectivityOverride = readConnectivity;

  static final instance = FlowNetworkService();
  final FlowEndpointPool _pool;
  final Connectivity _connectivity;
  final Stream<List<ConnectivityResult>>? _networkChangesOverride;
  final Future<List<ConnectivityResult>> Function()? _readConnectivityOverride;
  FlowProbeScheduler? _scheduler;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;
  StreamSubscription<void>? _failureSubscription;
  Timer? _periodic;
  bool _started = false;
  int _events = 0;
  int _connectivityRead = 0;
  Set<ConnectivityResult>? _lastConnectivity;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _lastConnectivity = null;
    final scheduler = _scheduler = FlowProbeScheduler(
      run: _pool.probe,
      cancel: _pool.cancelProbe,
      onError: (error) => LiggLogger().w('Flow IP 调度失败 (${error.runtimeType})'),
    );
    WidgetsBinding.instance.addObserver(this);
    scheduler.setActive(WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);
    _failureSubscription = _pool.revalidationRequests.listen((_) {
      scheduler.request();
    });
    try {
      _networkSubscription =
          (_networkChangesOverride ?? _connectivity.onConnectivityChanged)
              .listen(
        (results) {
          _events++;
          _networkChanged(results);
        },
        onError: (Object error) =>
            LiggLogger().w('Flow IP 网络监听失败 (${error.runtimeType})'),
      );
    } catch (error) {
      LiggLogger().w('Flow IP 网络监听不可用 (${error.runtimeType})');
    }
    await _refreshConnectivity(scheduler);
    if (!_started || !identical(_scheduler, scheduler)) return;
    await _pool.initialize();
    if (_started && identical(_scheduler, scheduler)) _startPeriodic();
  }

  Future<void> _refreshConnectivity(FlowProbeScheduler scheduler) async {
    final beforeRead = _events;
    final read = ++_connectivityRead;
    bool current() =>
        _started &&
        identical(_scheduler, scheduler) &&
        read == _connectivityRead &&
        beforeRead == _events;
    try {
      final results = await (_readConnectivityOverride?.call() ??
          _connectivity.checkConnectivity());
      if (!current()) return;
      // 恢复前台时读取状态快照，避免每次获得焦点都强制完整探测。
      // 事件流中的同类型通知仍使旧结果失效，例如切换到了另一个 Wi-Fi 接入点。
      if (!setEquals(_lastConnectivity, results.toSet())) {
        _networkChanged(results);
      }
    } catch (error) {
      if (!current()) return;
      scheduler.request(force: true);
      LiggLogger().w('读取 Flow IP 网络状态失败 (${error.runtimeType})');
    }
  }

  void _networkChanged(List<ConnectivityResult> results) {
    if (!_started) return;
    _lastConnectivity = results.toSet();
    // 相同网络类型的通知也可能表示切换到了不同的 Wi-Fi 接入点。
    // 保守地使旧结果失效，再通过防抖合并切换过程中的密集通知。
    _pool.networkChanged();
    _scheduler?.networkChanged(
        online: results.any((result) => result != ConnectivityResult.none));
  }

  void _startPeriodic() {
    if (WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _periodic ??= Timer.periodic(const Duration(minutes: 5), (_) {
      _pool.expireRoute();
      _scheduler?.request();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    final active = state == AppLifecycleState.resumed;
    _scheduler?.setActive(active);
    if (active) {
      unawaited(_refreshConnectivity(_scheduler!));
      _pool.expireRoute();
      _startPeriodic();
    } else {
      _connectivityRead++;
      _periodic?.cancel();
      _periodic = null;
    }
  }

  Future<void> stop() async {
    _started = false;
    _connectivityRead++;
    _scheduler?.dispose();
    _scheduler = null;
    _periodic?.cancel();
    _periodic = null;
    WidgetsBinding.instance.removeObserver(this);
    await _networkSubscription?.cancel();
    await _failureSubscription?.cancel();
    _networkSubscription = null;
    _failureSubscription = null;
  }
}

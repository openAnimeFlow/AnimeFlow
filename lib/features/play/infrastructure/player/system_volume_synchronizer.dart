import 'package:anime_flow/features/play/domain/playback_platform.dart';
import 'dart:async';

import 'package:anime_flow/core/utils/system_util.dart';

/// 负责系统音量监听，以及播放器音量与系统音量之间的同步。
class SystemVolumeSynchronizer implements PlaybackVolume {
  SystemVolumeSynchronizer({required this.onSystemVolumeChanged});

  static const syncInterval = Duration(milliseconds: 80);

  final void Function(double volume) onSystemVolumeChanged;

  Timer? _syncTimer;
  double? _pendingVolume;
  double? _lastKnownVolume;
  DateTime? _ignoreEventsUntil;
  StreamSubscription<double>? _volumeSubscription;
  bool _disposed = false;

  bool get isSupported => SystemUtil.supportsSystemVolumeSync;

  @override
  Future<void> initialize() async {
    if (!isSupported) return;

    await SystemUtil.configureSystemVolumeSync();
    if (_disposed) return;
    final systemVolume = await SystemUtil.getSystemVolume();
    if (_disposed) return;
    if (systemVolume != null) {
      _lastKnownVolume = systemVolume;
      onSystemVolumeChanged(systemVolume * 100);
    }
    if (_disposed) return;
    _volumeSubscription =
        SystemUtil.addSystemVolumeListener(_handleSystemVolumeChanged);
  }

  @override
  void scheduleSync(double normalizedVolume) {
    if (!isSupported || _disposed) return;

    _pendingVolume = normalizedVolume.clamp(0.0, 1.0).toDouble();
    if (_syncTimer?.isActive ?? false) return;

    _syncTimer = Timer(syncInterval, () {
      final pendingVolume = _pendingVolume;
      _pendingVolume = null;
      if (pendingVolume == null ||
          _isSameVolume(_lastKnownVolume, pendingVolume)) {
        return;
      }
      unawaited(_pushSystemVolume(pendingVolume));
    });
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_volumeSubscription?.cancel());
    _volumeSubscription = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    _pendingVolume = null;
  }

  void _handleSystemVolumeChanged(double volume) {
    if (_disposed) return;
    final normalized = volume.clamp(0.0, 1.0).toDouble();
    final ignoreUntil = _ignoreEventsUntil;
    if (ignoreUntil != null &&
        DateTime.now().isBefore(ignoreUntil) &&
        _isSameVolume(_lastKnownVolume, normalized)) {
      return;
    }

    _lastKnownVolume = normalized;
    _pendingVolume = null;
    onSystemVolumeChanged(normalized * 100);
  }

  Future<void> _pushSystemVolume(double normalizedVolume) async {
    _lastKnownVolume = normalizedVolume;
    _ignoreEventsUntil = DateTime.now().add(syncInterval * 2);
    await SystemUtil.setSystemVolume(normalizedVolume);
  }

  bool _isSameVolume(double? first, double? second) {
    if (first == null || second == null) return false;
    return (first - second).abs() < 0.01;
  }
}

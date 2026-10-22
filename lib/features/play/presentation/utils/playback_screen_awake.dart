import 'dart:async';

import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Adapts app visibility and playback activity to the platform wakelock.
class PlaybackScreenAwake with WidgetsBindingObserver {
  PlaybackScreenAwake(Stream<PlayerEvent> events) {
    WidgetsBinding.instance.addObserver(this);
    _subscription =
        events.listen(_onPlayerEvent, onDone: () => unawaited(dispose()));
  }

  late final StreamSubscription<PlayerEvent> _subscription;
  Future<void>? _updates;
  Future<void>? _disposal;
  bool _disposed = false;
  bool _playing = false;
  bool _requested = false;

  bool get _keepScreenOn =>
      !_disposed &&
      _playing &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  void _onPlayerEvent(PlayerEvent event) {
    if (_disposed) return;
    if (event is PlayerPlayingChanged) {
      _playing = event.playing;
    } else if (event is PlayerCompleted || event is PlayerError) {
      _playing = false;
    } else {
      return;
    }
    _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    _update(force: state == AppLifecycleState.resumed && _playing);
  }

  void _update({bool force = false}) {
    final enabled = _keepScreenOn;
    if (!force && enabled == _requested) return;
    _requested = enabled;
    // Preserve ordering: a delayed enable must not outlive the final disable.
    _updates = (_updates ?? Future<void>.value()).then((_) async {
      if (enabled && !_keepScreenOn) return;
      try {
        await WakelockPlus.toggle(enable: enabled);
      } catch (error, stackTrace) {
        if (_requested == enabled) _requested = !enabled;
        LiggLogger().e('设置播放屏幕常亮失败', error: error, stackTrace: stackTrace);
      }
    });
  }

  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    final cancelling = _subscription.cancel();
    _update();
    await cancelling;
    await _updates;
  }
}

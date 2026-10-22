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
  // Wakelock is process-wide. Pages withdraw only their own demand, and all
  // native changes share one queue across overlapping page lifetimes.
  static final _owners = <PlaybackScreenAwake>{};
  static Future<void> _updates = Future<void>.value();
  static bool _requested = false;
  Future<void>? _disposal;
  bool _disposed = false;
  bool _playing = false;

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

  Future<void> _update({bool force = false}) {
    if (_keepScreenOn) {
      _owners.add(this);
    } else {
      _owners.remove(this);
    }
    final enabled = _owners.isNotEmpty;
    if (!force && enabled == _requested) return _updates;
    _requested = enabled;
    // Preserve ordering: a delayed enable must not outlive the final disable.
    return _updates = _updates.then((_) async {
      if (enabled != _owners.isNotEmpty) return;
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
    final updating = _update();
    await cancelling;
    await updating;
  }
}

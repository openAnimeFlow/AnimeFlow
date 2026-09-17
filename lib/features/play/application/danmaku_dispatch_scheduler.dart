import 'dart:async';

import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';

/// 根据播放进度分发弹幕，生命周期由播放会话中的画布控制器管理。
class DanmakuDispatchScheduler {
  DanmakuDispatchScheduler({
    required this.readSnapshot,
    required this.onDanmaku,
  });

  final DanmakuDispatchSnapshot Function() readSnapshot;
  final void Function(Danmaku) onDanmaku;
  Timer? _ticker;
  final Set<Timer> _pending = {};
  int _generation = 0;

  void start() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void tick() {
    final snapshot = readSnapshot();
    if (!snapshot.playing ||
        !snapshot.danmakuOn ||
        snapshot.position == Duration.zero) {
      return;
    }

    final items = snapshot.danmakus[snapshot.position.inSeconds];
    if (items == null || items.isEmpty) return;
    final generation = _generation;
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      late final Timer pending;
      pending = Timer(
        Duration(milliseconds: index * 1000 ~/ items.length),
        () {
          _pending.remove(pending);
          final current = readSnapshot();
          if (generation != _generation ||
              current.epoch != snapshot.epoch ||
              !current.playing ||
              !current.danmakuOn) {
            return;
          }
          onDanmaku(item);
        },
      );
      _pending.add(pending);
    }
  }

  void invalidate() {
    _generation++;
    for (final timer in _pending) {
      timer.cancel();
    }
    _pending.clear();
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
    invalidate();
  }
}

class DanmakuDispatchSnapshot {
  const DanmakuDispatchSnapshot({
    required this.position,
    required this.playing,
    required this.danmakuOn,
    required this.danmakus,
    required this.epoch,
  });

  final Duration position;
  final bool playing;
  final bool danmakuOn;
  final Map<int, List<Danmaku>> danmakus;
  final int epoch;
}

import 'package:anime_flow/features/play/application/danmaku_canvas.dart';
import 'package:anime_flow/features/play/application/danmaku_session.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';

class CanvasDanmakuAdapter implements DanmakuCanvas {
  CanvasDanmakuAdapter(this.controller);

  final DanmakuController controller;

  @override
  void addDanmaku(Danmaku danmaku, int? currentUserId, {Color? color}) {
    final type = switch (danmaku.type) {
      4 => DanmakuItemType.bottom,
      5 => DanmakuItemType.top,
      _ => DanmakuItemType.scroll,
    };
    try {
      controller.addDanmaku(DanmakuContentItem(
        danmaku.message,
        color: color ?? danmaku.color,
        type: type,
        selfSend:
            danmaku.bgmUserId != null && danmaku.bgmUserId == currentUserId,
      ));
    } catch (_) {}
  }

  @override
  void syncPlayback(bool playing) {
    if (playing) {
      controller.resume();
    } else {
      controller.pause();
    }
  }

  @override
  void clear() => controller.clear();
}

extension DanmakuCanvasController on DanmakuSession {
  DanmakuController? get controller =>
      (canvas as CanvasDanmakuAdapter?)?.controller;
}

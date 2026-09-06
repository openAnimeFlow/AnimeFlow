import 'package:canvas_danmaku/canvas_danmaku.dart';

/// 负责播放器播放状态与弹幕画布之间的同步。
class DanmakuPlaybackSynchronizer {
  DanmakuController? controller;

  void syncPlayback(bool playing) {
    final current = controller;
    if (current == null) return;
    if (playing) {
      current.resume();
    } else {
      current.pause();
    }
  }

  void clear() {
    controller?.clear();
  }
}

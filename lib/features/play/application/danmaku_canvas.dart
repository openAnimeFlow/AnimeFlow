import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:flutter/material.dart';

/// 弹幕会话对画布的最小操作集合，具体绘制由展示层实现。
abstract interface class DanmakuCanvas {
  void addDanmaku(Danmaku danmaku, int? currentUserId, {Color? color});
  void syncPlayback(bool playing);
  void clear();
}

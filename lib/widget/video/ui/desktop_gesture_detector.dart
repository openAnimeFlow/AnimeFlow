import 'dart:async';

import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// 桌面端手势检测器
class DesktopGestureDetector extends StatelessWidget {
  final Widget child;
  static Timer? _hoverTimer;

  const DesktopGestureDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final videoStateController = Get.find<VideoStateController>();
    final videoUiStateController = Get.find<VideoUiStateController>();
    final playPageController = Get.find<PlayController>();
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // 空格键：暂停/播放
          if (event.logicalKey == LogicalKeyboardKey.space) {
            videoStateController.playOrPauseVideo();
            videoUiStateController.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.playStatusIndicator);
            return KeyEventResult.handled;
          }
          // 左方向键：快退10秒
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            final currentPosition = videoUiStateController.position.value;
            final duration = videoUiStateController.duration.value;
            final newPositionMs = (currentPosition - const Duration(seconds: 10)).inMilliseconds;
            final clampedMs = newPositionMs.clamp(0, duration.inMilliseconds);
            videoUiStateController.seekTo(Duration(milliseconds: clampedMs));
            videoUiStateController.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.horizontalDraggingIndicator);
            return KeyEventResult.handled;
          }
          // 右方向键：快进10秒
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            final currentPosition = videoUiStateController.position.value;
            final duration = videoUiStateController.duration.value;
            final newPositionMs = (currentPosition + const Duration(seconds: 10)).inMilliseconds;
            final clampedMs = newPositionMs.clamp(0, duration.inMilliseconds);
            videoUiStateController.seekTo(Duration(milliseconds: clampedMs));
            videoUiStateController.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.horizontalDraggingIndicator);
            return KeyEventResult.handled;
          }
          // 上方向键：增加音量
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            videoUiStateController.updateMainAxisAlignmentType(MainAxisAlignment.start);
            videoUiStateController.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.volumeIndicator);
            videoStateController.adjustVolumeByWheel(5.0); // 每次增加5%
            return KeyEventResult.handled;
          }
          // 下方向键：减少音量
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            videoUiStateController.updateMainAxisAlignmentType(MainAxisAlignment.start);
            videoUiStateController.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.volumeIndicator);
            videoStateController.adjustVolumeByWheel(-5.0); // 每次减少5%
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Listener(
        // 鼠标指针信号事件监听（用于鼠标滚轮）
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            videoUiStateController
                .updateMainAxisAlignmentType(MainAxisAlignment.start);
            videoUiStateController.updateIndicatorTypeAndShowIndicator(
                VideoControlsIndicatorType.volumeIndicator);

            // 处理鼠标滚轮事件：调整音量
            // 向上滚动增加音量，向下滚动减少音量
            // 除以20是为了控制调整幅度（每次约5%）
            var scrollDelta = -event.scrollDelta.dy / 20;
            videoStateController.adjustVolumeByWheel(scrollDelta);
          }
        },
        child: MouseRegion(
          // 鼠标移入事件
          // onEnter: (event) {
          //   videoUiStateController.showControlsUi();
          // },

          // 鼠标悬停事件
          onHover: (event) {
            _hoverTimer?.cancel();
            videoUiStateController.showControlsUi();
            _hoverTimer = Timer(const Duration(seconds: 3), () {
              videoUiStateController.hideControlsUi();
            });
          },

          // 鼠标移出事件
          onExit: (event) {
            _hoverTimer?.cancel();
            videoUiStateController.hideControlsUi(
                duration: const Duration(seconds: 3));
          },

          child: GestureDetector(
            // 双击事件
            // 使用自定义全屏方法，
            onDoubleTap: () {
              playPageController.toggleFullScreen();
            },

            // 单击事件
            onTap: () {
              videoStateController.playOrPauseVideo();
              videoUiStateController.updateIndicatorTypeAndShowIndicator(
                  VideoControlsIndicatorType.playStatusIndicator);
            },
            child: child,
          ),
        ),
      ),
    );
  }
}

import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/vibrate.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

/// 移动端手势监听组件
class MobileGestureDetector extends StatefulWidget {
  final Widget child;

  const MobileGestureDetector({super.key, required this.child});

  @override
  State<MobileGestureDetector> createState() => _MobileGestureDetectorState();
}

class _MobileGestureDetectorState extends State<MobileGestureDetector> {
  final setting = Storage.setting;
  double _verticalDragStartY = 0; // 垂直拖动开始时的Y坐标
  bool _isRightSide = false; // 是否在屏幕右半侧开始垂直拖动
  late double _fastForwardSpeed;
  late VideoStateController videoStateController;
  late VideoUiStateController videoUiStateController;

  @override
  void initState() {
    super.initState();
    _fastForwardSpeed =
        setting.get(PlaybackKey.fastForwardSpeed, defaultValue: 2.0);
    videoStateController = Get.find<VideoStateController>();
    videoUiStateController = Get.find<VideoUiStateController>();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      //单击事件
      onTap: () {
        videoUiStateController.showOrHideControlsUi();
        videoUiStateController.hideControlsUi(
            duration: const Duration(seconds: 3));
      },

      //双击事件
      onDoubleTap: () {
        videoStateController.playOrPauseVideo();
        videoUiStateController
            .updateMainAxisAlignmentType(MainAxisAlignment.start);
        videoUiStateController.updateIndicatorTypeAndShowIndicator(
            VideoControlsIndicatorType.playStatusIndicator);
      },

      //长按开始
      onLongPressStart: (LongPressStartDetails details) {
        if (videoStateController.playing.value) {
          vibrateMedium();
          videoStateController.startSpeedBoost(_fastForwardSpeed);
          videoUiStateController.updateIndicatorTypeAndShowIndicator(
              VideoControlsIndicatorType.speedIndicator);
        }
      },

      //长按结束
      onLongPressEnd: (LongPressEndDetails details) {
        videoStateController.endSpeedBoost();
        videoUiStateController.hideIndicator();
        videoUiStateController
            .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
      },

      // 水平拖动开始：调整播放进度
      onHorizontalDragStart: (DragStartDetails details) {
        videoUiStateController.startHorizontalDrag(
          details.globalPosition.dx,
          videoStateController.position.value,
        );
      },

      // 水平拖动更新：更新播放进度
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        videoUiStateController.updateHorizontalDrag(
          details.globalPosition.dx,
          screenWidth,
          videoStateController.duration.value,
        );
      },

      // 水平拖动结束：应用新的播放进度
      onHorizontalDragEnd: (DragEndDetails details) {
        videoStateController.seekTo(videoUiStateController.dragPosition.value);
        videoUiStateController.endHorizontalDrag();
      },

      // 水平拖动取消：恢复到拖动前的播放位置
      onHorizontalDragCancel: () {
        videoUiStateController.cancelHorizontalDrag();
      },

      // 垂直拖动开始：判断是调整音量还是亮度
      onVerticalDragStart: (DragStartDetails details) {
        // 记录拖动起始Y坐标
        _verticalDragStartY = details.globalPosition.dy;

        // 判断是否在屏幕右半侧开始拖动
        _isRightSide = details.globalPosition.dx > screenWidth / 2;
        videoUiStateController
            .updateMainAxisAlignmentType(MainAxisAlignment.start);
        if (_isRightSide) {
          // 右半屏：调整音量
          videoStateController.startVerticalDrag();
          videoUiStateController.updateMainAxisAlignmentType(MainAxisAlignment.start);
          videoUiStateController
              .updateIndicatorType(VideoControlsIndicatorType.volumeIndicator);
          videoUiStateController.showIndicator();
        } else {
          // 左半屏：调整屏幕亮度
          videoUiStateController.startBrightnessDragWithoutAutoHide();
          videoUiStateController.updateMainAxisAlignmentType(MainAxisAlignment.start);
          videoUiStateController.updateIndicatorType(
              VideoControlsIndicatorType.brightnessIndicator);
          videoUiStateController.showIndicator();
        }
      },

      // 垂直拖动更新：更新音量或亮度
      onVerticalDragUpdate: (DragUpdateDetails details) {
        final dragDistance = details.globalPosition.dy - _verticalDragStartY;

        if (_isRightSide) {
          // 垂直拖动（右半屏）：更新音量
          videoStateController.updateVerticalDrag(
            dragDistance, // 拖动的垂直距离
            screenHeight, // 屏幕高度
          );
        } else {
          // 垂直拖动（左半屏）：更新屏幕亮度
          videoUiStateController.updateBrightnessDrag(
            dragDistance, // 拖动的垂直距离
            screenHeight, // 屏幕高度
          );
        }
      },

      // 垂直拖动结束：完成拖动操作
      onVerticalDragEnd: (DragEndDetails details) {
        if (_isRightSide) {
          // 垂直拖动结束（右半屏）：应用新的音量
          videoStateController.endVerticalDrag();
          // 保持指示器显示，2秒后自动隐藏
          videoUiStateController.showIndicator();
          Future.delayed(const Duration(seconds: 2), () {
            if (!videoStateController.isVerticalDragging.value) {
              videoUiStateController.hideIndicator();
              videoUiStateController
                  .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
            }
          });
        } else {
          // 垂直拖动结束（左半屏）：结束亮度调整
          videoUiStateController.isBrightnessDragging.value = false;
          // 保持指示器显示，2秒后自动隐藏
          videoUiStateController.showIndicator();
          Future.delayed(const Duration(seconds: 2), () {
            if (!videoUiStateController.isBrightnessDragging.value) {
              videoUiStateController.hideIndicator();
              videoUiStateController
                  .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
            }
          });
        }
      },

      // 垂直拖动取消：用户中断拖动操作
      onVerticalDragCancel: () {
        if (_isRightSide) {
          // 垂直拖动取消（右半屏）：结束音量调整并隐藏指示器
          videoStateController.endVerticalDrag();
        } else {
          // 垂直拖动取消（左半屏）：结束亮度调整
          videoUiStateController.endBrightnessDrag();
        }
      },

      child: widget.child,
    );
  }
}

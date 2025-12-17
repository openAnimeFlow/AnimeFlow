import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/models/enums/drag_type.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

/// 移动端手势监听组件
class MobileGestureDetector extends StatelessWidget {
  final Widget child;

  const MobileGestureDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    double dragStartX = 0; // 拖动开始时的X坐标
    double dragStartY = 0; // 拖动开始时的Y坐标
    bool isRightSide = false; // 是否在屏幕右半侧开始拖动
    DragType? dragType; // 拖动类型：'horizontal'(水平) 或 'vertical'(垂直)
    final videoStateController = Get.find<VideoStateController>();
    final videoUiStateController = Get.find<VideoUiStateController>();

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
        videoUiStateController.updateIndicatorTypeAndShowIndicator(
            VideoControlsIndicatorType.playStatusIndicator);
      },

      // 拖动开始事件：记录起始位置并判断屏幕区域
      onPanStart: (details) {
        // 记录拖动起始坐标
        dragStartX = details.globalPosition.dx;
        dragStartY = details.globalPosition.dy;

        // 判断是否在屏幕右半侧开始拖动
        isRightSide = dragStartX > screenWidth / 2;

        // 重置拖动类型，等待后续判断
        dragType = null;
      },
      // 拖动更新事件：根据移动方向智能判断并执行相应操作
      onPanUpdate: (details) {
        // 获取当前拖动位置
        final currentX = details.globalPosition.dx;
        final currentY = details.globalPosition.dy;

        // 计算相对于起始位置的水平和垂直移动距离
        final deltaX = (currentX - dragStartX).abs();
        final deltaY = (currentY - dragStartY).abs();

        // 如果还没确定拖动类型，且移动距离超过阈值（10像素），则判断拖动方向
        if (dragType == null && (deltaX > 10 || deltaY > 10)) {
          if (deltaX > deltaY) {
            // 水平移动距离大于垂直距离 → 水平拖动（调整播放进度）
            dragType = DragType.horizontal;
            videoUiStateController.startHorizontalDrag(dragStartX);
          } else {
            // 垂直移动距离大于水平距离
            if (isRightSide) {
              // 且在右半屏 → 垂直拖动（调整音量）
              dragType = DragType.vertical;
              videoStateController.startVerticalDrag();
              videoUiStateController.updateIndicatorTypeAndShowIndicator(
                  VideoControlsIndicatorType.volumeIndicator);
            } else {
              // 左半屏 → 垂直拖动（调整屏幕亮度）
              dragType = DragType.vertical;
              videoUiStateController.startBrightnessDrag();
            }
          }
        }

        // 根据已确定的拖动类型，持续更新相应的值
        if (dragType == DragType.horizontal) {
          // 水平拖动：更新播放进度
          videoUiStateController.updateHorizontalDrag(currentX, screenWidth);
        } else if (dragType == DragType.vertical) {
          if (isRightSide) {
            // 垂直拖动（右半屏）：更新音量
            videoStateController.updateVerticalDrag(
              currentY - dragStartY, // 拖动的垂直距离
              screenHeight, // 屏幕高度（用于计算音量变化百分比）
            );
          } else {
            // 垂直拖动（左半屏）：更新屏幕亮度
            videoUiStateController.updateBrightnessDrag(
              currentY - dragStartY, // 拖动的垂直距离
              screenHeight, // 屏幕高度（用于计算亮度变化百分比）
            );
          }
        }
      },
      // 拖动结束事件：完成拖动操作
      onPanEnd: (details) {
        if (dragType == DragType.horizontal) {
          // 水平拖动结束：应用新的播放进度
          videoUiStateController.endHorizontalDrag();
        } else if (dragType == DragType.vertical) {
          if (isRightSide) {
            // 垂直拖动结束（右半屏）：应用新的音量并隐藏指示器
            videoStateController.endVerticalDrag();
          } else {
            // 垂直拖动结束（左半屏）：结束亮度调整
            videoUiStateController.endBrightnessDrag();
          }
        }

        // 重置拖动类型，准备下一次拖动
        dragType = null;
      },

      // 拖动取消事件：用户中断拖动操作
      onPanCancel: () {
        if (dragType == DragType.horizontal) {
          // 水平拖动取消：恢复到拖动前的播放位置
          videoUiStateController.cancelHorizontalDrag();
        } else if (dragType == DragType.vertical) {
          if (isRightSide) {
            // 垂直拖动取消（右半屏）：结束音量调整并隐藏指示器
            videoStateController.endVerticalDrag();
          } else {
            // 垂直拖动取消（左半屏）：结束亮度调整
            videoUiStateController.endBrightnessDrag();
          }
        }

        // 重置拖动类型
        dragType = null;
      },
      child: child,
    );
  }
}

import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/core/utils/vibrate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 移动端手势监听组件
class MobileGestureDetector extends ConsumerStatefulWidget {
  final Widget child;

  const MobileGestureDetector({super.key, required this.child});

  @override
  ConsumerState<MobileGestureDetector> createState() =>
      _MobileGestureDetectorState();
}

class _MobileGestureDetectorState extends ConsumerState<MobileGestureDetector> {
  double _verticalDragStartY = 0; // 垂直拖动开始时的Y坐标
  bool _isRightSide = false; // 是否在屏幕右半侧开始垂直拖动
  bool _isSpeedBoosting = false;
  late final PlaySession playSession;

  VideoUiNotifier get videoUiNotifier =>
      ref.read(videoUiProvider.notifier);

  void _endTemporaryPlaybackRate() {
    if (!_isSpeedBoosting) return;

    _isSpeedBoosting = false;
    playSession.endTemporaryPlaybackRate();
    videoUiNotifier.hideIndicator();
    videoUiNotifier
        .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
  }

  @override
  void dispose() {
    if (_isSpeedBoosting) {
      _isSpeedBoosting = false;
      playSession.endTemporaryPlaybackRate();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    playSession = ref.read(playSessionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      //单击事件
      onTap: () {
        videoUiNotifier.showOrHideControlsUi();
        videoUiNotifier.hideControlsUi(
            duration: const Duration(seconds: 3));
      },

      //双击事件
      onDoubleTap: () {
        playSession.playOrPauseVideo();
        videoUiNotifier.updateIndicatorTypeAndShowIndicator(
            VideoControlsIndicatorType.playStatusIndicator);
      },

      //长按开始
      onLongPressStart: (LongPressStartDetails details) {
        if (ref.read(playStateProvider).playing) {
          vibrateMedium();
          _isSpeedBoosting = true;
          playSession.setPlaybackRate(AppSettings.fastForwardSpeed,
              temporary: true);
          videoUiNotifier
              .updateMainAxisAlignmentType(MainAxisAlignment.start);
          videoUiNotifier
              .updateIndicatorType(VideoControlsIndicatorType.speedIndicator);
          videoUiNotifier.showIndicator();
        }
      },

      //长按结束
      onLongPressEnd: (LongPressEndDetails details) {
        _endTemporaryPlaybackRate();
      },

      onLongPressCancel: _endTemporaryPlaybackRate,

      // 水平拖动开始：调整播放进度
      onHorizontalDragStart: (DragStartDetails details) {
        if (!playSession.beginManualSeek()) return;
        videoUiNotifier.startHorizontalDrag(
          details.globalPosition.dx,
          ref.read(playStateProvider).position,
        );
      },

      // 水平拖动更新：更新播放进度
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        final double scale = 180000 / MediaQuery.sizeOf(context).width;
        videoUiNotifier.updateHorizontalDrag(
          details.globalPosition.dx,
          scale,
          ref.read(playStateProvider).duration,
        );
      },

      // 水平拖动结束：应用新的播放进度
      onHorizontalDragEnd: (DragEndDetails details) {
        playSession.finishManualSeek(videoUiNotifier.dragPosition);
        videoUiNotifier.endHorizontalDrag();
      },

      // 水平拖动取消：恢复到拖动前的播放位置
      onHorizontalDragCancel: () {
        videoUiNotifier.cancelHorizontalDrag();
        playSession.cancelManualSeek();
      },

      // 垂直拖动开始：判断是调整音量还是亮度
      onVerticalDragStart: (DragStartDetails details) {
        // 记录拖动起始Y坐标
        _verticalDragStartY = details.globalPosition.dy;

        // 判断是否在屏幕右半侧开始拖动
        _isRightSide = details.globalPosition.dx > screenWidth / 2;
        videoUiNotifier
            .updateMainAxisAlignmentType(MainAxisAlignment.start);
        if (_isRightSide) {
          // 右半屏：调整音量
          playSession.startVerticalDrag();
          videoUiNotifier
              .updateMainAxisAlignmentType(MainAxisAlignment.start);
          videoUiNotifier
              .updateIndicatorType(VideoControlsIndicatorType.volumeIndicator);
          videoUiNotifier.showIndicator();
        } else {
          // 左半屏：调整屏幕亮度
          videoUiNotifier.startBrightnessDragWithoutAutoHide();
          videoUiNotifier
              .updateMainAxisAlignmentType(MainAxisAlignment.start);
          videoUiNotifier.updateIndicatorType(
              VideoControlsIndicatorType.brightnessIndicator);
          videoUiNotifier.showIndicator();
        }
      },

      // 垂直拖动更新：更新音量或亮度
      onVerticalDragUpdate: (DragUpdateDetails details) {
        final dragDistance = details.globalPosition.dy - _verticalDragStartY;

        if (_isRightSide) {
          // 垂直拖动（右半屏）：更新音量
          playSession.updateVerticalDrag(
            dragDistance, // 拖动的垂直距离
            screenHeight, // 屏幕高度
          );
        } else {
          // 垂直拖动（左半屏）：更新屏幕亮度
          videoUiNotifier.updateBrightnessDrag(
            dragDistance, // 拖动的垂直距离
            screenHeight, // 屏幕高度
          );
        }
      },

      // 垂直拖动结束：完成拖动操作
      onVerticalDragEnd: (DragEndDetails details) {
        if (_isRightSide) {
          // 垂直拖动结束（右半屏）：应用新的音量
          playSession.endVerticalDrag();
          videoUiNotifier.updateIndicatorTypeAndShowIndicator(
              VideoControlsIndicatorType.volumeIndicator);
        } else {
          // 垂直拖动结束（左半屏）：结束亮度调整
          videoUiNotifier.setBrightnessDragging(false);
          videoUiNotifier.updateIndicatorTypeAndShowIndicator(
              VideoControlsIndicatorType.brightnessIndicator);
        }
      },

      // 垂直拖动取消：用户中断拖动操作
      onVerticalDragCancel: () {
        if (_isRightSide) {
          // 垂直拖动取消（右半屏）：结束音量调整并隐藏指示器
          playSession.endVerticalDrag();
        } else {
          // 垂直拖动取消（左半屏）：结束亮度调整
          videoUiNotifier.endBrightnessDrag();
        }
      },

      child: widget.child,
    );
  }
}

import 'dart:async';

import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/utils/vibrate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

class VideoUiStateController extends GetxController {
  /// 是否正在拖拽进度条
  final RxBool isDragging = false.obs;

  ///是否显示控件ui
  final RxBool isShowControlsUi = true.obs;

  /// 是否正在水平拖动
  final RxBool isHorizontalDragging = false.obs;

  /// 正在解析的标题
  final RxString parsingTitle = ''.obs;

  /// 拖动时的临时进度
  final Rx<Duration> dragPosition = Duration.zero.obs;

  /// 是否显示指示器ui
  final RxBool isShowIndicatorUi = false.obs;

  /// 指示器类型
  final Rx<VideoControlsIndicatorType> indicatorType =
      VideoControlsIndicatorType.noIndicator.obs;

  /// 主轴对齐类型
  final Rx<MainAxisAlignment> mainAxisAlignmentType =
      MainAxisAlignment.start.obs;

  /// 拖动相关
  double _dragStartX = 0;
  Duration _dragStartPosition = Duration.zero;

  /// 指示器计时器
  Timer? _indicatorTimer;

  /// 控件ui计时器
  Timer? _controlsUiTimer;

  /// 屏幕亮度相关
  final ScreenBrightnessPlatform _screenBrightness =
      ScreenBrightnessPlatform.instance;

  /// 保存原始亮度
  double _originalBrightness = 0.5;

  /// 当前亮度 0.0-1.0
  final RxDouble currentBrightness = 0.5.obs;

  /// 是否正在拖动调整亮度
  final RxBool isBrightnessDragging = false.obs;

  /// 拖动开始时的亮度
  double _dragStartBrightness = 0.5;

  @override
  void onInit() {
    super.onInit();
    _initializeBrightness();
  }

  //设置解析标题
  void setParsingTitle(String title) {
    parsingTitle.value = title;
  }

  //修改主轴类型
  void updateMainAxisAlignmentType(MainAxisAlignment type) {
    mainAxisAlignmentType.value = type;
  }

  // 更新指示器类型
  void updateIndicatorTypeAndShowIndicator(VideoControlsIndicatorType type) {
    indicatorType.value = type;
    _showIndicatorSetUp();
  }

  ///  更新指示器类型
  void updateIndicatorType(VideoControlsIndicatorType type) {
    indicatorType.value = type;
  }

  ///  显示指示器
  void showIndicator() {
    _indicatorTimer?.cancel();
    isShowIndicatorUi.value = true;
  }

  /// 隐藏指示器
  void hideIndicator() {
    _indicatorTimer?.cancel();
    isShowIndicatorUi.value = false;
  }

  // 显示指示器and
  void _showIndicatorSetUp() {
    _indicatorTimer?.cancel();
    isShowIndicatorUi.value = true;
    _indicatorTimer = Timer(const Duration(seconds: 3), () {
      isShowIndicatorUi.value = false;
      updateIndicatorTypeAndShowIndicator(
          VideoControlsIndicatorType.noIndicator);
      updateMainAxisAlignmentType(MainAxisAlignment.start);
    });
  }

  // 开始拖拽
  void startDrag() {
    isDragging.value = true;
  }

  //  结束拖拽
  void endDrag(Duration pos) {
    isDragging.value = false;
  }

  ///显示获|隐藏控件ui
  void showOrHideControlsUi() {
    isShowControlsUi.value = !isShowControlsUi.value;
  }

  ///显示控件ui
  void showControlsUi() {
    isShowControlsUi.value = true;
  }

  ///隐藏控件ui
  void hideControlsUi({Duration? duration}) {
    _controlsUiTimer?.cancel();
    if (duration != null && duration > Duration.zero) {
      _controlsUiTimer = Timer(duration, () {
        isShowControlsUi.value = false;
      });
    } else {
      isShowControlsUi.value = false;
    }
  }

  // 开始水平拖动
  void startHorizontalDrag(double startX, Duration position) {
    _dragStartX = startX;
    _dragStartPosition = position;
    isHorizontalDragging.value = true;
    isDragging.value = true;

    // 显示控件UI
    showControlsUi();

    // 取消之前的自动隐藏UI计时器
    cancelUiTimer();
  }

  ///取消ui计时器
  void cancelUiTimer() {
    _controlsUiTimer?.cancel();
  }

  // 更新水平拖动进度
  void updateHorizontalDrag(
      double currentX, double screenWidth, Duration duration) {
    if (duration <= Duration.zero) return;

    // 计算拖动距离
    final dragDistance = currentX - _dragStartX;

    // 根据屏幕宽度计算时间偏移（滑动整个屏幕宽度 = 总时长）
    // 添加系数 0.5 减小拖动敏感度，使拖动更精细
    final timeOffset =
        (dragDistance / screenWidth) * duration.inMilliseconds * 0.5;

    // 计算新的播放位置
    var newPosition = _dragStartPosition.inMilliseconds + timeOffset.toInt();

    // 限制在有效范围内
    newPosition = newPosition.clamp(0, duration.inMilliseconds);

    dragPosition.value = Duration(milliseconds: newPosition);
  }

  // 结束水平拖动
  void endHorizontalDrag() {
    if (isHorizontalDragging.value) {
      // 更新视频进度
      isHorizontalDragging.value = false;
      isDragging.value = false;

      // 1秒后隐藏控件UI
      hideControlsUi(duration: const Duration(seconds: 1));
    }
  }

  // 取消水平拖动
  void cancelHorizontalDrag() {
    if (isHorizontalDragging.value) {
      isHorizontalDragging.value = false;
      isDragging.value = false;
      // 恢复到拖动开始前的位置
      dragPosition.value = _dragStartPosition;
      // 1秒后隐藏控件UI
      hideControlsUi(duration: const Duration(seconds: 1));
    }
  }

  // 初始化并保存原始亮度
  Future<void> _initializeBrightness() async {
    try {
      // 获取当前应用屏幕亮度
      final brightness = await _screenBrightness.application;
      _originalBrightness = brightness;
      currentBrightness.value = brightness;
    } catch (e) {
      // 如果获取失败，使用默认值
      _originalBrightness = 0.5;
      currentBrightness.value = 0.5;
    }
  }

  // 开始垂直拖动调整亮度
  void startBrightnessDrag() {
    _dragStartBrightness = currentBrightness.value;
    isBrightnessDragging.value = true;

    // 取消之前的自动隐藏UI计时器
    _controlsUiTimer?.cancel();

    // 显示控件UI
    showControlsUi();

    // 显示亮度指示器
    updateIndicatorTypeAndShowIndicator(
        VideoControlsIndicatorType.brightnessIndicator);
  }

  // 开始垂直拖动调整亮度（不设置自动隐藏定时器）
  void startBrightnessDragWithoutAutoHide() {
    _dragStartBrightness = currentBrightness.value;
    isBrightnessDragging.value = true;
  }

  // 更新亮度
  void updateBrightnessDrag(double dragDistance, double screenHeight) {
    // 向上拖动减少亮度，向下拖动增加亮度
    final brightnessChange = -(dragDistance / screenHeight);
    double newBrightness =
        (_dragStartBrightness + brightnessChange).clamp(0.0, 1.0);

    if (newBrightness >= 1.0 && currentBrightness.value < 1.0) {
      vibrateHeavy();
    } else if (newBrightness <= 0.0 && currentBrightness.value > 0.0) {
      vibrateHeavy();
    }
    currentBrightness.value = newBrightness;

    _screenBrightness.setApplicationScreenBrightness(newBrightness);
  }

  // 结束垂直拖动亮度
  void endBrightnessDrag() {
    isBrightnessDragging.value = false;

    // 隐藏亮度指示器
    hideIndicator();
    updateIndicatorType(VideoControlsIndicatorType.noIndicator);
    updateMainAxisAlignmentType(MainAxisAlignment.start);

    // 1秒后隐藏控件UI
    hideControlsUi(duration: const Duration(seconds: 1));
  }

  // 恢复原始屏幕亮度
  Future<void> _resetBrightness() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _screenBrightness.resetApplicationScreenBrightness();
        currentBrightness.value = _originalBrightness;
      } catch (e) {
        // 如果重置失败，尝试设置为原始值
        try {
          await _screenBrightness
              .setApplicationScreenBrightness(_originalBrightness);
          currentBrightness.value = _originalBrightness;
        } catch (_) {}
      }
    });
  }

  @override
  void onClose() {
    _indicatorTimer?.cancel();
    _controlsUiTimer?.cancel();
    _resetBrightness();
    super.onClose();
  }
}

import 'dart:async';

import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

class VideoUiStateController extends GetxController {
  final Player player;
  final RxBool playing = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final Rx<Duration> buffer = Duration.zero.obs;
  final RxBool _isBuffering = false.obs; // 是否正在缓冲
  final RxDouble networkSpeed = 0.0.obs; // 网络速率 (MB/s)
  final RxBool isDragging = false.obs; // 是否正在拖拽进度条
  final RxBool isShowControlsUi = true.obs; //是否显示控件ui
  final RxBool isHorizontalDragging = false.obs; // 是否正在水平拖动
  final RxString parsingTitle = ''.obs; // 正在解析的标题
  final Rx<Duration> dragPosition = Duration.zero.obs; // 拖动时的临时进度
  final RxBool isShowIndicatorUi = false.obs; // 是否显示指示器ui
  final Rx<VideoControlsIndicatorType> indicatorType =
      VideoControlsIndicatorType.noIndicator.obs; // 指示器类型
  final Rx<MainAxisAlignment> mainAxisAlignmentType =
      MainAxisAlignment.start.obs; // 主轴对齐类型

  // 拖动相关
  double _dragStartX = 0;
  Duration _dragStartPosition = Duration.zero;

  // 网速计算相关
  Duration _lastBufferPosition = Duration.zero;
  DateTime _lastBufferTime = DateTime.now();
  static const double _estimatedBitrateMBps = 2.0; // 假设平均比特率 2 MB/s

  //指示器计时器
  Timer? _indicatorTimer;

  //控件ui计时器
  Timer? _controlsUiTimer;

  // 屏幕亮度相关
  final ScreenBrightnessPlatform _screenBrightness =
      ScreenBrightnessPlatform.instance;
  double _originalBrightness = 0.5; // 保存原始亮度
  final RxDouble currentBrightness = 0.5.obs; // 当前亮度 0.0-1.0
  final RxBool isBrightnessDragging = false.obs; // 是否正在拖动调整亮度
  double _dragStartBrightness = 0.5; // 拖动开始时的亮度

  VideoUiStateController(this.player) {
    // 初始化状态
    duration.value = player.state.duration;
    position.value = player.state.position;
    playing.value = player.state.playing;
    buffer.value = player.state.buffer;

    // 监听播放器播放状态变化
    player.stream.playing.listen((playing) {
      this.playing.value = playing;
    });

    // 监听进度
    player.stream.position.listen((pos) {
      if (!isDragging.value) {
        position.value = pos;
      }
    });

    // 监听总时长
    player.stream.duration.listen((dur) {
      duration.value = dur;
    });

    // 监听缓冲进度
    player.stream.buffer.listen((buf) {
      buffer.value = buf;
      _calculateNetworkSpeed(buf);
    });

    // 监听缓冲状态
    player.stream.buffering.listen((buffering) {
      _isBuffering.value = buffering;

      // 只有当播放器有内容（duration > 0）并且正在播放时才显示缓冲指示器
      if (duration.value > Duration.zero && playing.value) {
        if (buffering) {
          // 开始缓冲，重置网速计算
          _resetNetworkSpeed();
          updateIndicatorType(VideoControlsIndicatorType.bufferingIndicator);
          updateMainAxisAlignmentType(MainAxisAlignment.center);
          showIndicator();
        } else {
          // 缓冲结束
          if (indicatorType.value ==
              VideoControlsIndicatorType.bufferingIndicator) {
            hideIndicator();
            updateIndicatorType(VideoControlsIndicatorType.noIndicator);
          }
        }
      }
    });
  }

  // 计算网络速率 (MB/s)
  void _calculateNetworkSpeed(Duration currentBuffer) {
    final now = DateTime.now();
    final timeDiffMs = now.difference(_lastBufferTime).inMilliseconds;

    // 每500毫秒更新一次网速
    if (timeDiffMs >= 500 && _isBuffering.value) {
      final bufferDiffMs =
          currentBuffer.inMilliseconds - _lastBufferPosition.inMilliseconds;

      if (bufferDiffMs > 0 && timeDiffMs > 0) {
        // 计算缓冲速度倍率（缓冲进度增长 / 实际时间）
        final bufferSpeedMultiplier = bufferDiffMs / timeDiffMs;

        // 根据估计的比特率计算实际网速 (MB/s)
        // 网速 = 比特率 × 缓冲速度倍率
        networkSpeed.value = _estimatedBitrateMBps * bufferSpeedMultiplier;
      }

      _lastBufferPosition = currentBuffer;
      _lastBufferTime = now;
    }
  }

  // 重置网速计算
  void _resetNetworkSpeed() {
    _lastBufferPosition = buffer.value;
    _lastBufferTime = DateTime.now();
    networkSpeed.value = 0.0;
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

  // 跳转到指定位置
  void seekTo(Duration pos) {
    player.seek(pos);
  }

  // 开始拖拽
  void startDrag() {
    isDragging.value = true;
  }

  // 结束拖拽
  void endDrag(Duration pos) {
    isDragging.value = false;
    seekTo(pos);
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
  void startHorizontalDrag(double startX) {
    _dragStartX = startX;
    _dragStartPosition = position.value;
    isHorizontalDragging.value = true;
    isDragging.value = true;

    // 显示控件UI
    showControlsUi();

    // 取消之前的自动隐藏UI计时器
    _controlsUiTimer?.cancel();
  }

  // 更新水平拖动进度
  void updateHorizontalDrag(double currentX, double screenWidth) {
    if (duration.value <= Duration.zero) return;

    // 计算拖动距离
    final dragDistance = currentX - _dragStartX;

    // 根据屏幕宽度计算时间偏移（滑动整个屏幕宽度 = 总时长）
    final timeOffset =
        (dragDistance / screenWidth) * duration.value.inMilliseconds;

    // 计算新的播放位置
    var newPosition = _dragStartPosition.inMilliseconds + timeOffset.toInt();

    // 限制在有效范围内
    newPosition = newPosition.clamp(0, duration.value.inMilliseconds);

    dragPosition.value = Duration(milliseconds: newPosition);
  }

  // 结束水平拖动
  void endHorizontalDrag() {
    if (isHorizontalDragging.value) {
      // 更新视频进度
      seekTo(dragPosition.value);
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
  Future<void> initializeBrightness() async {
    try {
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

  // 更新垂直拖动亮度
  void updateBrightnessDrag(double dragDistance, double screenHeight) {
    // 向上拖动减少亮度，向下拖动增加亮度
    final brightnessChange = -(dragDistance / screenHeight);
    double newBrightness =
        (_dragStartBrightness + brightnessChange).clamp(0.0, 1.0);

    currentBrightness.value = newBrightness;

    // 更新屏幕亮度
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
    try {
      await _screenBrightness.resetApplicationScreenBrightness();
      currentBrightness.value = _originalBrightness;
    } catch (e) {
      // 如果重置失败，尝试设置为原始值
      try {
        await _screenBrightness
            .setApplicationScreenBrightness(_originalBrightness);
        currentBrightness.value = _originalBrightness;
      } catch (_) {
        // 忽略错误
      }
    }
  }

  @override
  void onClose() {
    _indicatorTimer?.cancel();
    _controlsUiTimer?.cancel();
    _resetBrightness();
    super.onClose();
  }
}

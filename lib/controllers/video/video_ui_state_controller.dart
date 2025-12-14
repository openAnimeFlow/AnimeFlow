import 'dart:async';

import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';

class VideoUiStateController extends GetxController {
  final Player player;
  final RxBool playing = false.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final Rx<Duration> buffer = Duration.zero.obs;
  final RxBool isBuffering = false.obs; // 是否正在缓冲
  final RxDouble networkSpeed = 0.0.obs; // 网络速率 (MB/s)
  final RxBool isDragging = false.obs; // 是否正在拖拽进度条
  final RxBool isShowControlsUi = true.obs; //是否显示控件ui
  final RxBool isHorizontalDragging = false.obs; // 是否正在水平拖动
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

  VideoUiStateController(this.player) {
    // 初始化状态，防止 player 已经加载完成导致 stream 不触发
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
      isBuffering.value = buffering;

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
            updateMainAxisAlignmentType(MainAxisAlignment.start);
            networkSpeed.value = 0.0; // 重置网速显示
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
    if (timeDiffMs >= 500 && isBuffering.value) {
      final bufferDiffMs = currentBuffer.inMilliseconds - _lastBufferPosition.inMilliseconds;

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

  //修改主轴类型
  void updateMainAxisAlignmentType(MainAxisAlignment type) {
    mainAxisAlignmentType.value = type;
  }

  // 更新指示器类型
  void updateIndicatorTypeAndShowIndicator(VideoControlsIndicatorType type) {
    indicatorType.value = type;
    _showIndicatorSetUp();
  }

  void updateIndicatorType(VideoControlsIndicatorType type) {
    indicatorType.value = type;
  }

  void showIndicator() {
    _indicatorTimer?.cancel();
    isShowIndicatorUi.value = true;
  }

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
    position.value = dragPosition.value; // 实时更新位置显示
  }

  // 结束水平拖动
  void endHorizontalDrag() {
    if (isHorizontalDragging.value) {
      seekTo(dragPosition.value);
      isHorizontalDragging.value = false;
      isDragging.value = false;
    }
  }

  // 取消水平拖动
  void cancelHorizontalDrag() {
    if (isHorizontalDragging.value) {
      isHorizontalDragging.value = false;
      isDragging.value = false;
      // 恢复到拖动开始前的位置
      position.value = _dragStartPosition;
    }
  }

  @override
  void onClose() {
    _indicatorTimer?.cancel();
    super.onClose();
  }
}

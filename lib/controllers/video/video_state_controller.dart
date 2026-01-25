import 'dart:async';

import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoStateController extends GetxController {
  late Player player;
  late VideoController videoController;
  final RxBool playing = false.obs; //视频播放状态
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final RxDouble volume = 100.0.obs; //音量 0-100
  final RxBool isVerticalDragging = false.obs; //是否正在垂直拖动调整音量
  final RxDouble rate = 1.0.obs;
  final RxBool buffering = false.obs;

  //记录原始倍速
  double _originalSpeed = 1.0;

  // 垂直拖动相关
  double _dragStartVolume = 100.0;

  @override
  void onInit() {
    super.onInit();
    player = Player();
    videoController = VideoController(player);
    // 监听播放器播放状态
    player.stream.playing.listen((playing) {
      this.playing.value = playing;
    });

    // 监听播放器音量变化
    player.stream.volume.listen((vol) {
      volume.value = vol;
    });

    // 监听播放器倍速变化
    player.stream.rate.listen((r) {
      rate.value = r;
    });

    // 监听播放进度
    player.stream.position.listen((pos) {
      position.value = pos;
    });

    // 监听视频时长
    player.stream.duration.listen((dur) {
      duration.value = dur;
    });
  }

  @override
  void dispose() {
    super.dispose();
    player.dispose();
  }

  ///暂停|播放
  void playOrPauseVideo() {
    player.playOrPause();
  }

  // /// 清理播放资源
  // void disposeVideo() {
  //   player.open(
  //     Media(
  //       '',
  //     ),
  //   );
  // }

  ///设置播放倍数
  void startSpeedBoost(double speed) {
    // 保存原始的倍速
    _originalSpeed = rate.value;
    // 设置新的倍速
    rate.value = speed;
    player.setRate(speed);
  }

  /// 跳转到指定位置
  void seekTo(Duration pos) {
    player.seek(pos);
  }

  /// 结束速度提升
  void endSpeedBoost() {
    // 恢复为长按前的倍速
    rate.value = _originalSpeed;
    player.setRate(_originalSpeed);
  }

  ///设置视频音量（绝对值）
  void setVolume(double newVolume) {
    double clampedVolume = newVolume.clamp(0.0, 100.0);
    player.setVolume(clampedVolume);
  }

  // 开始垂直拖动调整音量
  void startVerticalDrag() {
    _dragStartVolume = volume.value;
    isVerticalDragging.value = true;
  }

  //滚轮调节音量
  void adjustVolumeByWheel(double delta) {
    double newVolume = (volume.value + delta);
    setVolume(newVolume);
  }

  // 更新垂直拖动音量
  void updateVerticalDrag(double dragDistance, double screenHeight) {
    final volumeChange = -(dragDistance / screenHeight) * 100;
    double newVolume = _dragStartVolume + volumeChange;
    setVolume(newVolume);
  }

  // 结束垂直拖动
  void endVerticalDrag() {
    isVerticalDragging.value = false;
    // 2秒后隐藏音量指示器
    Future.delayed(const Duration(seconds: 2), () {
      if (!isVerticalDragging.value) {}
    });
  }
}

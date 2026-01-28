import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 视频播放进度条组件
class VideoProgressBar extends StatefulWidget {
  const VideoProgressBar({super.key});

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  late VideoUiStateController videoUiStateController;
  late VideoStateController videoStateController;

  @override
  void initState() {
    super.initState();
    videoUiStateController = Get.find<VideoUiStateController>();
    videoStateController = Get.find<VideoStateController>();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Obx(
        () {
          final max =
              videoStateController.duration.value.inMilliseconds.toDouble();
          // 如果正在水平拖动，使用拖动位置；否则使用当前播放位置
          final value = videoUiStateController.isHorizontalDragging.value
              ? videoUiStateController.dragPosition.value.inMilliseconds
                  .toDouble()
              : videoStateController.position.value.inMilliseconds.toDouble();
          final buffer =
              videoStateController.buffered.value.inMilliseconds.toDouble();

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 背景层
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape: SliderComponentShape.noThumb,
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: Colors.black.withValues(alpha: 0.3),
                  disabledActiveTrackColor: Colors.black.withValues(alpha: 0.3),
                  disabledThumbColor: Colors.transparent,
                  trackShape: _CustomTrackShape(),
                ),
                child: Slider(
                  value: max > 0 ? max : 1.0,
                  min: 0.0,
                  max: max > 0 ? max : 1.0,
                  onChanged: null, // 禁用交互
                ),
              ),
              // 缓冲层
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape: SliderComponentShape.noThumb,
                  // 隐藏滑块
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: Colors.white.withValues(alpha: 0.4),
                  // 缓冲颜色
                  disabledActiveTrackColor: Colors.white.withValues(alpha: 0.4),
                  disabledThumbColor: Colors.transparent,
                  trackShape: _CustomTrackShape(),
                ),
                child: Slider(
                  value: buffer.clamp(0.0, max > 0 ? max : 1.0),
                  min: 0.0,
                  max: max > 0 ? max : 1.0,
                  onChanged: null, // 禁用交互
                ),
              ),
              // 播放进度条
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Theme.of(context).colorScheme.primary,
                  trackShape: _CustomTrackShape(),
                ),
                child: Slider(
                  value: value.clamp(0.0, max > 0 ? max : 1.0),
                  min: 0.0,
                  max: max > 0 ? max : 1.0,
                  // 进度条开始拖动
                  onChangeStart: (_) => videoUiStateController.startDrag(),
                  // 进度条正在拖动
                  onChanged: (v) {
                    // 更新拖动位置，但不更新实际播放位置
                    videoUiStateController.dragPosition.value =
                        Duration(milliseconds: v.toInt());
                  },
                  // 进度条结束拖动
                  onChangeEnd: (v) {
                    videoStateController
                        .seekTo(Duration(milliseconds: v.toInt()));
                    videoUiStateController
                        .endDrag(Duration(milliseconds: v.toInt()));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 自定义TrackShape，用于解决缓冲条和进度条对齐问题
class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    // Flutter Slider 默认两端有 Padding 来容纳 Thumb
    // 这里手动模拟这个 Padding，确保无 Thumb 的 Slider 与有 Thumb 的 Slider 轨道长度一致
    final double trackLeft = offset.dx; // 补偿 Thumb 半径
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width; // 补偿两侧 Thumb 半径
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

/// 视频时间显示组件
class VideoTimeDisplay extends StatelessWidget {
  final VideoUiStateController videoUiStateController;
  final VideoStateController videoStateController;

  const VideoTimeDisplay({
    super.key,
    required this.videoUiStateController,
    required this.videoStateController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 如果正在水平拖动，使用拖动位置；否则使用当前播放位置
      final position = videoUiStateController.isHorizontalDragging.value
          ? videoUiStateController.dragPosition.value
          : videoStateController.position.value;
      final duration = videoStateController.duration.value;

      return Text(
        "${FormatTimeUtil.formatDuration(position)} / ${FormatTimeUtil.formatDuration(duration)}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
    });
  }
}

/// 弹幕输入框
class DanmakuTextField extends StatelessWidget {
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final bool leftIcon;
  final bool rightIcon;

  const DanmakuTextField(
      {super.key,
      this.iconColor,
      this.textColor,
      this.leftIcon = true,
      this.rightIcon = true,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          leftIcon
              ? Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: iconColor,
                )
              : const SizedBox.shrink(),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(
                fontSize: 14,
                height: 1.0,
              ),
              decoration: InputDecoration(
                hintText: '发送弹幕开发中...',
                hintStyle: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.0,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
              ),
            ),
          ),
          rightIcon
              ? IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: iconColor,
                  ),
                  onPressed: () {
                    // 发送弹幕逻辑
                  },
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// 电池图标
class BatteryIcon extends StatelessWidget {
  final int battery;
  final BatteryState batteryState;
  final double? size;
  /// 旋转角度（度数，0-360）
  final double? angle;

  const BatteryIcon(
      {super.key,
      this.size = 16,
      this.angle,
      required this.battery,
      required this.batteryState});

  @override
  Widget build(BuildContext context) {
    final isCharging = batteryState == BatteryState.charging;

    IconData iconData;
    Color iconColor;

    if (isCharging) {
      // 充电状态
      iconData = Icons.battery_charging_full;
      iconColor = Colors.greenAccent;
    } else {
      // 非充电状态
      if (battery <= 10) {
        iconData = Icons.battery_0_bar;
        iconColor = Colors.redAccent;
      } else if (battery <= 20) {
        iconData = Icons.battery_1_bar;
        iconColor = Colors.orangeAccent;
      } else if (battery <= 50) {
        iconData = Icons.battery_3_bar;
        iconColor = Colors.white;
      } else if (battery <= 80) {
        iconData = Icons.battery_5_bar;
        iconColor = Colors.white;
      } else {
        iconData = Icons.battery_full;
        iconColor = battery >= 90 ? Colors.greenAccent : Colors.white;
      }
    }

    final icon = Icon(iconData, color: iconColor, size: size);

    if (angle != null && angle != 0) {
      return Transform.rotate(
        angle: angle! * 3.141592653589793 / 180, // 将角度转换为弧度
        child: icon,
      );
    }

    return icon;
  }
}

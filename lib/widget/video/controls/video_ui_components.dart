import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/utils/timeUtil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 视频播放进度条组件
class VideoProgressBar extends StatelessWidget {
  final VideoUiStateController videoUiStateController;

  const VideoProgressBar({super.key, required this.videoUiStateController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Obx(() {
        final max =
            videoUiStateController.duration.value.inMilliseconds.toDouble();
        // 如果正在水平拖动，使用拖动位置；否则使用当前播放位置
        final value = videoUiStateController.isHorizontalDragging.value
            ? videoUiStateController.dragPosition.value.inMilliseconds
                .toDouble()
            : videoUiStateController.position.value.inMilliseconds.toDouble();
        final buffer =
            videoUiStateController.buffer.value.inMilliseconds.toDouble();

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // 缓冲条
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
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
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
                  videoUiStateController.position.value =
                      Duration(milliseconds: v.toInt());
                },
                // 进度条结束拖动
                onChangeEnd: (v) => videoUiStateController
                    .endDrag(Duration(milliseconds: v.toInt())),
              ),
            ),
          ],
        );
      }),
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
  final VideoUiStateController videoController;

  const VideoTimeDisplay({super.key, required this.videoController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 如果正在水平拖动，使用拖动位置；否则使用当前播放位置
      final position = videoController.isHorizontalDragging.value
          ? videoController.dragPosition.value
          : videoController.position.value;
      final duration = videoController.duration.value;

      return Text(
        "${TimeUtil.formatDuration(position)} / ${TimeUtil.formatDuration(duration)}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
    });
  }
}

class DanmakuTextField extends StatelessWidget {
  const DanmakuTextField({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Icon(
          Icons.chat_bubble_outline,
          size: 18,
          color: Colors.white
              .withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.0,
            ),
            decoration: InputDecoration(
              hintText: '发送弹幕...',
              hintStyle: TextStyle(
                color: Colors.white
                    .withValues(
                    alpha: 0.5),
                fontSize: 14,
                height: 1.0,
              ),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets
                  .symmetric(
                  vertical: 0),
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.send_rounded,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () {
            // 发送弹幕逻辑
          },
        ),
      ],
    );
  }
}

import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:anime_flow/features/network_speed/presentation/network_speed_provider.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

/// 中间区域控件
class MiddleAreaControl extends ConsumerStatefulWidget {
  const MiddleAreaControl({super.key});

  @override
  ConsumerState<MiddleAreaControl> createState() => _MiddleAreaControlState();
}

class _MiddleAreaControlState extends ConsumerState<MiddleAreaControl> {
  final PlayController playController = Get.find<PlayController>();
  final VideoUiStateController videoUiStateController = Get.find<VideoUiStateController>();

  @override
  Widget build(BuildContext context) {
    const double topAreaHeight = 50.0;
    final speedAsync = ref.watch(networkSpeedStreamProvider(2000));
    final speed = speedAsync.asData?.value;
    const textStyle = TextStyle(
      shadows: [
        Shadow(color: Colors.black, offset: Offset(0, 0), blurRadius: 3)
      ],
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    return Obx(
      () => Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: videoUiStateController.mainAxisAlignmentType.value,
          children: [
            //指示器Icon
            switch (videoUiStateController.indicatorType.value) {
              //无指示器
              VideoControlsIndicatorType.noIndicator => const SizedBox.shrink(),

              //缓冲指示器
              // TODO 指示器显示逻辑需要优化(多个地方可能会调用videoUiStateController.updateIndicatorType(VideoControlsIndicatorType.noIndicator)隐藏指示器,当前正在显示器的指示器可能会被其他地方条用隐藏方法导致当前指示器被提前关闭)
              VideoControlsIndicatorType.bufferingIndicator => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 5,
                    ),
                    const SizedBox(height: 8),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        ' ${Utils.formatBytesPerSec(speed?.download ?? 0)}',
                        style: textStyle,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        '正在缓冲...',
                        style: textStyle,
                      ),
                    ]),
                  ],
                ),

              //音量指示器
              VideoControlsIndicatorType.volumeIndicator => Container(
                  width: 180,
                  height: 35,
                  margin: const EdgeInsets.only(top: topAreaHeight),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: LinearProgressIndicator(
                          value: playController.volume.value / 100,
                          backgroundColor: Colors.white30,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      Positioned(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 5),
                          child: Icon(
                            playController.volume.value == 0
                                ? Icons.volume_off
                                : playController.volume.value < 50
                                    ? Icons.volume_down
                                    : Icons.volume_up,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              //播放状态指示器
              VideoControlsIndicatorType.playStatusIndicator => Container(
                  height: 50,
                  width: 60,
                  margin: const EdgeInsets.only(top: topAreaHeight),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    playController.playing.value
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 33,
                    color: Colors.white54,
                  ),
                ),

              //横向拖动指示器
              VideoControlsIndicatorType.horizontalDraggingIndicator =>
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${FormatTimeUtil.formatDuration(videoUiStateController.dragPosition.value)} / ${FormatTimeUtil.formatDuration(playController.duration.value)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              //解析指示器
              VideoControlsIndicatorType.parsingIndicator => Column(
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      playController.parseResult.value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    )
                  ],
                ),

              //亮度指示器
              VideoControlsIndicatorType.brightnessIndicator => Container(
                  width: 180,
                  height: 35,
                  margin: const EdgeInsets.only(top: topAreaHeight),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: LinearProgressIndicator(
                          value: videoUiStateController.currentBrightness.value,
                          backgroundColor: Colors.white30,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 5),
                        child: Icon(
                          videoUiStateController.currentBrightness.value < 0.3
                              ? Icons.brightness_2
                              : videoUiStateController.currentBrightness.value <
                                      0.7
                                  ? Icons.brightness_4
                                  : Icons.brightness_high,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

              //加速指示器
              VideoControlsIndicatorType.speedIndicator => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  margin: const EdgeInsets.only(top: topAreaHeight),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fast_forward_rounded,
                        color: Colors.white,
                        size: 35,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${playController.rate.value.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            }
          ],
        ),
      ),
    );
  }
}

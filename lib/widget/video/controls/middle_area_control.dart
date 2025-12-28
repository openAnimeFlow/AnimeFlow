import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/utils/timeUtil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 中间区域控件
class MiddleAreaControl extends StatelessWidget {
  const MiddleAreaControl({super.key});

  @override
  Widget build(BuildContext context) {
    final videoStateController = Get.find<VideoStateController>();
    final videoUiStateController = Get.find<VideoUiStateController>();

    return Obx(() => Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment:
                videoUiStateController.mainAxisAlignmentType.value,
            children: [
              //指示器Icon
              switch (videoUiStateController.indicatorType.value) {
                //无指示器
                VideoControlsIndicatorType.noIndicator =>
                  const SizedBox.shrink(),

                //缓冲指示器
                VideoControlsIndicatorType.bufferingIndicator => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 5,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '正在缓冲...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                //音量指示器
                VideoControlsIndicatorType.volumeIndicator => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          videoStateController.volume.value == 0
                              ? Icons.volume_off
                              : videoStateController.volume.value < 50
                                  ? Icons.volume_down
                                  : Icons.volume_up,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: LinearProgressIndicator(
                            value: videoStateController.volume.value / 100,
                            backgroundColor: Colors.white30,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary),
                          ),
                        )
                      ],
                    ),
                  ),

                //播放状态指示器
                VideoControlsIndicatorType.playStatusIndicator => Container(
                    height: 50,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      videoStateController.playing.value
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 33,
                      color: Colors.white54,
                    ),
                  ),

                //横向拖动指示器
                VideoControlsIndicatorType.horizontalDraggingIndicator =>
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${TimeUtil.formatDuration(videoUiStateController.dragPosition.value)} / ${TimeUtil.formatDuration(videoUiStateController.duration.value)}',
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
                        videoUiStateController.parsingTitle.value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      )
                    ],
                  ),

                //亮度指示器
                VideoControlsIndicatorType.brightnessIndicator => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          videoUiStateController.currentBrightness.value < 0.3
                              ? Icons.brightness_2
                              : videoUiStateController.currentBrightness.value <
                                      0.7
                                  ? Icons.brightness_4
                                  : Icons.brightness_high,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: LinearProgressIndicator(
                            value:
                                videoUiStateController.currentBrightness.value,
                            backgroundColor: Colors.white30,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary),
                          ),
                        )
                      ],
                    ),
                  ),

                //加速指示器
                VideoControlsIndicatorType.speedIndicator => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fast_forward_rounded,
                          color: Colors.white,
                          size: 35,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${videoStateController.rate.value.toStringAsFixed(1)}x',
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
        ));
  }
}

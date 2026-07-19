import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/video_ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerProgressBar extends ConsumerWidget {
  const PlayerProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playController = ref.read(playSessionProvider);
    final videoUiStateController = ref.read(videoUiProvider.notifier);
    final isHorizontalDragging = ref.watch(
      videoUiProvider.select((state) => state.isHorizontalDragging),
    );
    final dragPosition = ref.watch(
      videoUiProvider.select((state) => state.dragPosition),
    );
    final duration = ref.watch(playStateProvider.select((s) => s.duration));
    final position = ref.watch(playStateProvider.select((s) => s.position));
    final buffered = ref.watch(playStateProvider.select((s) => s.buffered));
    return SizedBox(
      height: 20,
      child: Builder(builder: (context) {
        final max = duration.inMilliseconds.toDouble();
        final value = isHorizontalDragging
            ? dragPosition.inMilliseconds.toDouble()
            : position.inMilliseconds.toDouble();
        final buffer = buffered.inMilliseconds.toDouble();

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
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
                onChanged: null,
              ),
            ),
            // 缓冲层
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                thumbShape: SliderComponentShape.noThumb,
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.white.withValues(alpha: 0.4),
                disabledActiveTrackColor: Colors.white.withValues(alpha: 0.4),
                disabledThumbColor: Colors.transparent,
                trackShape: _CustomTrackShape(),
              ),
              child: Slider(
                value: buffer.clamp(0.0, max > 0 ? max : 1.0),
                min: 0.0,
                max: max > 0 ? max : 1.0,
                onChanged: null,
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
                onChangeStart: (v) {
                  videoUiStateController.startProgressDrag(
                    Duration(milliseconds: v.toInt()),
                  );
                  playController.stopPlaying();
                },
                onChanged: (v) {
                  final position = Duration(milliseconds: v.toInt());
                  videoUiStateController.setHorizontalDragPosition(
                    position,
                  );
                  playController.updateBufferingForPendingSeek(position);
                },
                onChangeEnd: (v) {
                  playController.seekTo(Duration(milliseconds: v.toInt()));
                  videoUiStateController.endHorizontalDrag();
                  playController.startPlaying();
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

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
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

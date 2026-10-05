import 'package:material_ui/material_ui.dart';

class PlayerProgressBar extends StatelessWidget {
  const PlayerProgressBar({
    super.key,
    required this.duration,
    required this.position,
    required this.buffered,
    required this.isDragging,
    required this.dragPosition,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final Duration duration;
  final Duration position;
  final Duration buffered;
  final bool isDragging;
  final Duration dragPosition;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Builder(builder: (context) {
        final max = duration.inMilliseconds.toDouble();
        final value = isDragging
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
                onChangeStart: onChangeStart,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class MiniPlayerProgressBar extends StatelessWidget {
  const MiniPlayerProgressBar({
    super.key,
    required this.duration,
    required this.position,
    required this.buffered,
  });

  final Duration duration;
  final Duration position;
  final Duration buffered;

  @override
  Widget build(BuildContext context) {
    final totalMilliseconds = duration.inMilliseconds;
    final progress = totalMilliseconds > 0
        ? (position.inMilliseconds / totalMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final buffer = totalMilliseconds > 0
        ? (buffered.inMilliseconds / totalMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 3,
      child: CustomPaint(
        size: Size.infinite,
        painter: _MiniProgressPainter(
          progress: progress,
          buffer: buffer,
          backgroundColor: colorScheme.onSurface.withValues(alpha: 0.28),
          bufferColor: colorScheme.onSurface.withValues(alpha: 0.52),
          progressColor: colorScheme.primary,
        ),
      ),
    );
  }
}

class _MiniProgressPainter extends CustomPainter {
  const _MiniProgressPainter({
    required this.progress,
    required this.buffer,
    required this.backgroundColor,
    required this.bufferColor,
    required this.progressColor,
  });

  final double progress;
  final double buffer;
  final Color backgroundColor;
  final Color bufferColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Rect.fromLTWH(0, 0, size.width, size.height);
    final radius = Radius.circular(size.height / 2);
    final trackRRect = RRect.fromRectAndRadius(track, radius);
    canvas.drawRRect(trackRRect, Paint()..color = backgroundColor);

    final bufferWidth = size.width * buffer;
    if (bufferWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, bufferWidth, size.height),
          radius,
        ),
        Paint()..color = bufferColor,
      );
    }

    final progressWidth = size.width * progress;
    if (progressWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, progressWidth, size.height),
          radius,
        ),
        Paint()..color = progressColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniProgressPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      buffer != oldDelegate.buffer ||
      backgroundColor != oldDelegate.backgroundColor ||
      bufferColor != oldDelegate.bufferColor ||
      progressColor != oldDelegate.progressColor;
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

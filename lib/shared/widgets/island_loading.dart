import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

/// 灵动岛风格的胶囊加载提示。
class IslandLoading extends StatefulWidget {
  const IslandLoading({
    super.key,
    this.label,
    this.semanticLabel,
    this.showBackground = true,
    this.isPlaying = true,
    this.color,
  });

  /// 可选的可见提示文字，不传时仅显示动画。
  final String? label;
  final String? semanticLabel;

  /// 是否显示磨砂胶囊背景。
  final bool showBackground;

  /// 暂停时保留当前动画帧，恢复时从该帧继续。
  final bool isPlaying;

  /// 波形及文字的颜色；不传时使用主题颜色。
  final Color? color;

  @override
  State<IslandLoading> createState() => _IslandLoadingState();
}

class _IslandLoadingState extends State<IslandLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant IslandLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.isPlaying && !MediaQuery.disableAnimationsOf(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = SizedBox(
      height: 48,
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: widget.showBackground ? 18 : 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: const Size(34, 24),
                painter: _IslandPulsePainter(
                  phase: _controller.value,
                  color: widget.color ??
                      (widget.showBackground
                          ? colors.primaryContainer
                          : colors.primary),
                ),
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.color ??
                        (widget.showBackground
                            ? Colors.white
                            : colors.onSurface),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      liveRegion: widget.semanticLabel != null || widget.label != null,
      child: ExcludeSemantics(
        child: !widget.showBackground
            ? content
            : ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff101116).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: content,
                  ),
                ),
              ),
      ),
    );
  }
}

class _IslandPulsePainter extends CustomPainter {
  const _IslandPulsePainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 4; i++) {
      final wave = (math.sin(phase * math.pi * 2 - i * 0.9) + 1) / 2;
      final height = 5 + wave * 15;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(4 + i * 8.5, size.height / 2),
          width: 4,
          height: height,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: color.a * (0.55 + wave * 0.45)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IslandPulsePainter oldDelegate) =>
      phase != oldDelegate.phase || color != oldDelegate.color;
}

@Preview(name: '文字提示', group: 'Island Loading', size: Size(320, 160))
Widget islandLoadingLabelPreview() => const _IslandLoadingPreview();

@Preview(name: '紧凑模式', group: 'Island Loading', size: Size(320, 160))
Widget islandLoadingCompactPreview() =>
    const _IslandLoadingPreview(compact: true);

@Preview(name: '无背景 · 暂停', group: 'Island Loading', size: Size(320, 160))
Widget islandLoadingTransparentPreview() => const MaterialApp(
      home: Scaffold(
        body: Center(
          child: IslandLoading(
            label: '已暂停',
            showBackground: false,
            isPlaying: false,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );

class _IslandLoadingPreview extends StatelessWidget {
  const _IslandLoadingPreview({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: compact
                    ? const [Color(0xff24223b), Color(0xff655b9c)]
                    : const [Color(0xffc3e7f1), Color(0xffe9d1e5)],
              ),
            ),
            child: Center(
              child: IslandLoading(
                label: compact ? null : '正在加载',
                semanticLabel: '正在加载',
              ),
            ),
          ),
        ),
      );
}

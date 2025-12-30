import 'package:flutter/material.dart';

class ThemePreviewCard extends StatefulWidget {
  final Color bg;
  final Color primary;
  final IconData icon;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final Color? subtitleColor;
  final bool selected;
  final Widget? overlay;

  const ThemePreviewCard({
    super.key,
    required this.bg,
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.selected = false,
    this.overlay,
    this.titleColor,
    this.subtitleColor,
  });

  @override
  State<ThemePreviewCard> createState() => _ThemePreviewCardState();
}

class _ThemePreviewCardState extends State<ThemePreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 位置动画：从左侧到右侧（前60%的时间）
    // 容器宽度：110 - 24 (左右padding) = 86
    // 最大位置：86 - 22 (圆宽度) = 64
    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 64.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    // 缩放动画：圆变成对勾（后50%的时间，从50%开始）
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (widget.selected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ThemePreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 110,
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.selected ? widget.primary : Colors.white24,
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.primary.withValues(alpha: 0.6),
                      blurRadius: 16,
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, color: widget.primary, size: 28),
              const SizedBox(height: 16),
              Text(widget.title,
                  style: TextStyle(
                      color: widget.titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.subtitle,
                  style: TextStyle(fontSize: 12, color: widget.subtitleColor)),
              const Spacer(),

              /// 底部按钮
              Container(
                height: 22,
                decoration: BoxDecoration(
                  color: widget.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // 圆形按钮的透明度（在转换前显示）
                    final circleOpacity = 1.0 - _scaleAnimation.value;
                    // 对勾图标的透明度（在转换后显示）
                    final checkOpacity = _scaleAnimation.value;
                    
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 圆形按钮（只在需要时显示）
                        if (circleOpacity > 0.01)
                          Positioned(
                            left: _positionAnimation.value,
                            top: 0,
                            child: IgnorePointer(
                              ignoring: circleOpacity < 0.5,
                              child: Opacity(
                                opacity: circleOpacity,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: widget.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // 对勾图标
                        if (checkOpacity > 0.01)
                          Positioned(
                            left: _positionAnimation.value,
                            top: 0,
                            child: IgnorePointer(
                              ignoring: checkOpacity < 0.5,
                              child: Opacity(
                                opacity: checkOpacity,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: widget.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        /// 斜切覆盖
        if (widget.overlay != null) widget.overlay!,
      ],
    );
  }
}


class ThemeColorCard extends StatelessWidget {
  final Color background;
  final Color header;
  final Color text;
  final double borderWidth;
  final Color borderColor;
  final Color button;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;

  const ThemeColorCard({
    super.key,
    required this.background,
    required this.header,
    required this.text,
    required this.button,
    this.borderColor = Colors.black45,
    this.margin,
    this.borderWidth = 3, this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 120,
      margin: margin,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(width: borderWidth, color: borderColor),
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: boxShadow,

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部栏
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: header,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),

          // 文本条
          _line(text, width: 80),
          _line(text, width: 40),
          _line(text, width: 60),

          const Spacer(),

          // 底部按钮
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: button,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
  Widget _line(Color color, {double width = 60}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Container(
      height: 6,
      width: width,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.hardEdge,
    ),
  );
}


class DiagonalOverlay extends StatelessWidget {
  const DiagonalOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipPath(
        clipper: _DiagonalClipper(),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18), color: Colors.white38),
        ),
      ),
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 1, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_) => false;
}

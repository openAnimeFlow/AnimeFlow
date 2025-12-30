import 'package:flutter/material.dart';

class ThemePreviewCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 110,
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? primary : Colors.white24,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.6),
                      blurRadius: 16,
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: primary, size: 28),
              const SizedBox(height: 16),
              Text(title,
                  style: TextStyle(color: titleColor,
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor)),
              const Spacer(),

              /// 底部按钮模拟
              Container(
                height: 22,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// 右上角选中 ✔
        if (selected)
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: primary,
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
          ),

        /// 斜切覆盖（跟随系统）
        if (overlay != null) overlay!,
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

import 'package:flutter/material.dart';

class ThemePreviewCard extends StatelessWidget {
  final Color background;
  final Color header;
  final Color text;
  final double borderWidth;
  final Color borderColor;
  final Color button;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;

  const ThemePreviewCard({
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
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
}

class DiagonalClipper extends CustomClipper<Path> {
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

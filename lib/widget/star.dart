import 'package:flutter/material.dart';
///评分星星图标
class StarView extends StatelessWidget {
  final double score;
  final double? iconSize;

  const StarView({super.key, required this.score, this.iconSize = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final fullStars = (score / 2).floor();
        final halfStars = (score / 2) - fullStars >= 0.5;
        if (index < fullStars) {
          return Icon(
            Icons.star_rate_rounded,
            color: Colors.amberAccent,
            size: iconSize,
          );
        } else if (index == fullStars && halfStars) {
          return Icon(
            Icons.star_half_rounded,
            color: Colors.amberAccent,
            size: iconSize,
          );
        } else {
          return Icon(
            Icons.star_outline_rounded,
            color: Colors.amberAccent,
            size: iconSize,
          );
        }
      }),
    );
  }
}

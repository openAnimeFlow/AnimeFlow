import 'package:flutter/material.dart';

class RankingView extends StatelessWidget {
  final int ranking;
  final FontWeight? fontWeight;
  final double? fontSize;

  const RankingView(
      {super.key, required this.ranking, this.fontWeight = FontWeight.bold, this.fontSize = 8.0});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: isDark ? Theme.of(context).disabledColor : Colors.amber[400],
      ),
      child: Text(
        ranking.toString(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black,
              offset: Offset(0.5, 0.5),
              blurRadius: 1,
            )
          ],
        ),
      ),
    );
  }
}

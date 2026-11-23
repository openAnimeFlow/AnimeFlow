import 'package:material_ui/material_ui.dart';

/// 顶部渐隐遮罩，同时阻止点击穿透到遮罩下方的内容。
class TopGradientMask extends StatelessWidget {
  const TopGradientMask({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return AbsorbPointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor,
              backgroundColor.withValues(alpha: 0.7),
              backgroundColor.withValues(alpha: 0),
            ],
            stops: const [0, 0.4, 1],
          ),
        ),
      ),
    );
  }
}

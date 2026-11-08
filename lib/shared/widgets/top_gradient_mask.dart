import 'package:material_ui/material_ui.dart';

/// 顶部渐隐遮罩，同时阻止点击穿透到遮罩下方的内容。
class TopGradientMask extends StatelessWidget {
  const TopGradientMask({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return AbsorbPointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              surface.withValues(alpha: 1),
              surface.withValues(alpha: 0.7),
              surface.withValues(alpha: 0),
            ],
            stops: const [0, 0.4, 1],
          ),
        ),
      ),
    );
  }
}

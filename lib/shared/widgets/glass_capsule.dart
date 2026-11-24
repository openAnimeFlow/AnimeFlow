import 'dart:ui';

import 'package:material_ui/material_ui.dart';

class GlassCapsule extends StatelessWidget {
  const GlassCapsule({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  static Color surfaceColor(ColorScheme colors) =>
      colors.surface.withValues(alpha: 0.76);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(28);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? surfaceColor(colors),
            borderRadius: radius,
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class SubjectCardSkeleton extends StatelessWidget {
  const SubjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = Color.lerp(
      baseColor,
      isDark ? colorScheme.onSurface : colorScheme.surface,
      isDark ? 0.08 : 0.65,
    )!;

    return Stack(
      children: [
        Positioned.fill(
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

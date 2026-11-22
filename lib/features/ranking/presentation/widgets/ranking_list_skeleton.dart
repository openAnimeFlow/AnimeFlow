import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class RankingListSkeleton extends StatelessWidget {
  const RankingListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final baseColor = colors.surfaceContainerHighest;
    final highlightColor = Color.lerp(
      baseColor,
      isDark ? colors.onSurface : colors.surface,
      isDark ? 0.08 : 0.65,
    )!;

    Widget placeholder({double? width, required double height}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(15),
          ),
        );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            placeholder(width: 100, height: 160),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          placeholder(width: 140, height: 16),
                          const SizedBox(height: 7),
                          placeholder(width: 90, height: 18),
                          const SizedBox(height: 8),
                          placeholder(width: 110, height: 14),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    placeholder(width: 28, height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

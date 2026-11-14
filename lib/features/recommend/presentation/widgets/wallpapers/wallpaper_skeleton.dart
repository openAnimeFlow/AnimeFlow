import 'package:anime_flow/features/recommend/presentation/widgets/wallpapers/justified_layout.dart';
import 'package:anime_flow/shared/widgets/card_skeleton.dart';
import 'package:material_ui/material_ui.dart';

/// 占位图片的比例序列：横竖混排，用于首屏骨架和「加载更多」的尾部占位。
///
/// 尾部占位必须与真实图片走同一次 [justifyImageRows] 计算，
/// 才能继续填满当前未满的最后一行，而不是另起一行。
List<double> wallpaperPlaceholderRatios(int count) {
  if (count <= 0) return const [];
  const cycle = [2 / 3, 2 / 3, 16 / 9, 2 / 3, 2 / 3, 16 / 9];
  return List<double>.generate(count, (index) => cycle[index % cycle.length]);
}

/// 网格内单个占位卡片：外边距与圆角与真实卡片保持一致。
class WallpaperSkeletonTile extends StatelessWidget {
  const WallpaperSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: WallpaperSkeleton.spacing),
        child: CardSkeleton(borderRadius: WallpaperSkeleton.cardRadius),
      );
}

/// 与壁纸墙同构的骨架屏。
///
/// 直接复用内容态的两端对齐算法 [justifyImageRows] 计算行高与每列宽度，
/// 因此加载态和内容态的排版完全一致，数据到达时不会发生跳变。
/// 作为 sliver 使用：首屏铺满可见区域，加载下一页时只显示一行。
class WallpaperSkeleton extends StatelessWidget {
  const WallpaperSkeleton({
    super.key,
    required this.availableWidth,
    this.rows = 4,
  });

  static const spacing = 12.0;
  static const cardRadius = 16.0;

  /// 内容区可用宽度（已扣除页面左右留白）。
  final double availableWidth;

  /// 需要铺满的行数；首屏按视口铺满。
  final int rows;

  static double targetHeightFor(double availableWidth) =>
      availableWidth < 600 ? 180 : 220;

  /// 按视口高度推算需要几行骨架才能盖住首屏。
  static int rowsFor({
    required double availableWidth,
    required double viewportHeight,
  }) {
    final targetHeight = targetHeightFor(availableWidth);
    if (!viewportHeight.isFinite || viewportHeight <= 0) return 4;
    return (viewportHeight / targetHeight).ceil().clamp(2, 6);
  }

  List<JustifiedImageRow> _rows() {
    final isCompact = availableWidth < 600;
    // 多给几项输入，保证取前 [rows] 行时不会因为末行合并规则少行。
    final ratios = wallpaperPlaceholderRatios(rows * 4 + 2);
    return justifyImageRows(
      ratios,
      availableWidth: availableWidth,
      targetHeight: targetHeightFor(availableWidth),
      spacing: spacing,
      minItemWidth: isCompact ? 120 : 0,
      minItemsPerRow: isCompact ? 2 : 1,
      maxItemsPerRow: isCompact ? 2 : null,
    ).take(rows).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final layout = _rows();
    return SliverList.builder(
      itemCount: layout.length,
      itemBuilder: (context, index) {
        final row = layout[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < row.widths.length; i++) ...[
                if (i > 0) const SizedBox(width: spacing),
                SizedBox(
                  width: row.widths[i],
                  height: row.imageHeight,
                  child: const CardSkeleton(borderRadius: cardRadius),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

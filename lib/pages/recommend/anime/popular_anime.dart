import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/pages/recommend/anime/anime_notifier.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class PopularAnimeView extends ConsumerWidget {
  const PopularAnimeView({super.key});

  /// 首屏加载时的骨架卡片数量。
  static const int _initialSkeletonCount = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotAsync = ref.watch(animeHotProvider);

    return hotAsync.when(
      loading: () => SliverMainAxisGroup(
        slivers: [
          _buildTitleSliver(),
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: LayoutUtil.getCrossAxisCount(context),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: _buildSkeleton(context),
                ),
              ),
              childCount: _initialSkeletonCount,
            ),
          ),
        ],
      ),
      error: (error, stackTrace) => _buildSection(
        context,
        child: _buildErrorContent(context, ref, error.toString()),
      ),
      data: (hotState) => SliverMainAxisGroup(
        slivers: [
          _buildTitleSliver(),
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: LayoutUtil.getCrossAxisCount(context),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                if (index < hotState.items.length) {
                  final subject = hotState.items[index].subject;
                  final subjectBasicData = SubjectBasicData(
                    id: subject.id,
                    name: subject.nameCN ?? subject.name,
                    image: subject.images.large,
                  );
                  return InkWell(
                    onTap: () =>
                        AnimeInfoRoute.fromData(subjectBasicData).push(context),
                    child: SubjectCard(
                      image: subject.images.large,
                      title: subject.nameCN ?? subject.name,
                    ),
                  );
                }

                final skeletonCount =
                    hotState.hasMore && hotState.isLoading ? 3 : 0;
                if (index < hotState.items.length + skeletonCount) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: _buildSkeleton(context),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
              childCount: hotState.items.length +
                  (hotState.hasMore && hotState.isLoading ? 3 : 0),
            ),
          ),
          if (hotState.errorMessage != null && hotState.items.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () => ref.read(animeHotProvider.notifier).loadMore(),
                  child: Column(
                    spacing: 8,
                    children: [
                      Text(
                        '加载失败',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(Icons.refresh),
                    ],
                  ),
                ) ,
              ),
            ),
          if (!hotState.hasMore && hotState.errorMessage == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Row(
                    children: [
                      Expanded(child: _buildHorizontalRuleIcons(context)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '没有更多了',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(child: _buildHorizontalRuleIcons(context)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required Widget child}) {
    return SliverMainAxisGroup(
      slivers: [
        _buildTitleSliver(),
        SliverToBoxAdapter(child: child),
      ],
    );
  }

  Widget _buildTitleSliver() {
    return const SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '热门动画',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildErrorContent(
    BuildContext context,
    WidgetRef ref,
    String errorMessage,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(animeHotProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalRuleIcons(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const iconSize = 24.0;
        const spacing = 4.0;
        const iconWidth = iconSize + spacing;
        final iconCount = (constraints.maxWidth / iconWidth).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            iconCount > 0 ? iconCount : 1,
            (index) => Padding(
              padding:
                  EdgeInsets.only(right: index < iconCount - 1 ? spacing : 0),
              child: Icon(
                Icons.horizontal_rule_rounded,
                size: iconSize,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = SystemUtil.isDarkTheme(context);
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final containerColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;

    return Stack(
      children: [
        Positioned.fill(
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

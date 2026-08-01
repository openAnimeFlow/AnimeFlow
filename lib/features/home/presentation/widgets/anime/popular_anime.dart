import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/features/home/presentation/providers/anime_provider.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/core/utils/layout_util.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/shared/widgets/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class PopularAnimeView extends ConsumerWidget {
  const PopularAnimeView({super.key});

  /// 首屏加载时的骨架卡片数量。
  static const int _initialSkeletonCount = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hotAsync = ref.watch(animeHotProvider);

    return hotAsync.when(
      loading: () => SliverMainAxisGroup(
        slivers: [
          _buildTitleSliver(l10n),
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
                  padding: const EdgeInsets.all(2),
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
        child: _buildErrorContent(context, ref, error.toString(), l10n),
        l10n: l10n,
      ),
      data: (hotState) => SliverMainAxisGroup(
        slivers: [
          _buildTitleSliver(l10n),
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
                  return InkWell(
                    onTap: () => AnimeInfoRoute.fromExtra(InfoRouteExtra(
                      id: subject.id,
                      name: subject.nameCN.isEmpty
                          ? subject.name
                          : subject.nameCN,
                      image: subject.images.large,
                    )).push(context),
                    child: SubjectCard(
                      image: subject.images.large,
                      title: subject.nameCN.isEmpty
                          ? subject.name
                          : subject.nameCN,
                    ),
                  );
                }

                final skeletonCount =
                    hotState.hasMore && hotState.isLoading ? 3 : 0;
                if (index < hotState.items.length + skeletonCount) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
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
                        l10n.loadFailed,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(Icons.refresh),
                    ],
                  ),
                ),
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
                          l10n.noMoreContent,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildSection(BuildContext context,
      {required Widget child, required AppLocalizations l10n}) {
    return SliverMainAxisGroup(
      slivers: [
        _buildTitleSliver(l10n),
        SliverToBoxAdapter(child: child),
      ],
    );
  }

  Widget _buildTitleSliver(AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.popularAnimeTitle,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildErrorContent(
    BuildContext context,
    WidgetRef ref,
    String errorMessage,
    AppLocalizations l10n,
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
            l10n.loadFailed,
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
            label: Text(l10n.reload),
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

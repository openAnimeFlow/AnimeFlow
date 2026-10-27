import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/navigation/args/info_route_extra.dart';
import 'package:anime_flow/features/home/presentation/providers/anime_provider.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/widgets/subject_card.dart';
import 'package:anime_flow/shared/widgets/card_skeleton.dart';
import 'package:anime_flow/shared/widgets/no_more_indicator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PopularAnimeView extends ConsumerWidget {
  const PopularAnimeView({super.key, required this.contentWidth});

  final double contentWidth;

  SliverGridDelegateWithFixedCrossAxisCount get _gridDelegate {
    final compact = contentWidth < 600;
    final spacing = compact ? 10.0 : 15.0;
    final minCardWidth = compact ? 120.0 : 200.0;
    final crossAxisCount = ((contentWidth + spacing) / (minCardWidth + spacing))
        .floor()
        .clamp(3, 7);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: 0.7,
    );
  }

  /// 首屏加载时的骨架卡片数量。
  static const int _initialSkeletonCount = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hotAsync = ref.watch(animeHotProvider);
    final grid = _gridDelegate;
    final cardWidth =
        (contentWidth - grid.crossAxisSpacing * (grid.crossAxisCount - 1)) /
            grid.crossAxisCount;
    final coverCacheWidth = (cardWidth * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 4096);

    return hotAsync.when(
      loading: () => SliverMainAxisGroup(
        slivers: [
          _buildTitleSliver(l10n),
          SliverGrid(
            gridDelegate: _gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => const Center(
                child: CardSkeleton(),
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
          if (hotState.isRefreshing)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          if (hotState.hasUpdate) _buildUpdateSliver(context, ref, l10n),
          SliverGrid(
            gridDelegate: _gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                if (index < hotState.items.length) {
                  final subject = hotState.items[index].subject;
                  return InkWell(
                    onTap: () =>
                        appNavigatorOf(context).openAnimeInfoFromExtra<void>(
                            context,
                            InfoRouteExtra(
                              id: subject.id,
                              name: subject.nameCN.isEmpty
                                  ? subject.name
                                  : subject.nameCN,
                              image: subject.images.large,
                            )),
                    child: SubjectCard(
                      memCacheWidth: coverCacheWidth,
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
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: CardSkeleton(),
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
          if (hotState.hasUpdate) _buildUpdateSliver(context, ref, l10n),
          if (!hotState.hasMore &&
              hotState.errorMessage == null &&
              !hotState.hasUpdate &&
              !hotState.isRefreshing)
            const SliverToBoxAdapter(
              child: NoMoreIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildUpdateSliver(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: TextButton.icon(
        onPressed: () {
          Scrollable.maybeOf(context)?.position.jumpTo(0);
          ref.read(animeHotProvider.notifier).applyUpdate();
        },
        icon: const Icon(Icons.refresh),
        label: Text(l10n.popularAnimeUpdateAvailable),
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
}

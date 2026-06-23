import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/pages/user/provider/user_collection_provider.dart';
import 'package:anime_flow/routes/model/info_route_extra.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/ranking.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionTabView extends ConsumerWidget {
  final TabController tabController;
  final List<String> tabs;
  final Map<int, GlobalKey<RefreshIndicatorState>> refreshIndicatorKeys;

  const CollectionTabView({
    super.key,
    required this.tabController,
    required this.tabs,
    required this.refreshIndicatorKeys,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabBarView(
      controller: tabController,
      children: List.generate(tabs.length, (tabIndex) {
        final type = tabIndex + 1;
        return _CollectionTabView(
          type: type,
          refreshIndicatorKey: refreshIndicatorKeys[type]!,
        );
      }),
    );
  }
}

class _CollectionTabView extends ConsumerWidget {
  final int type;
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;

  const _CollectionTabView({
    required this.type,
    required this.refreshIndicatorKey,
  });

  static const double _refreshIndicatorOffset =
      kToolbarHeight + kTextTabBarHeight;
  static const double _minHorizontalPadding = 10;
  static const double _loadMoreTriggerDistance = 200;

  Future<void> _onRefresh(WidgetRef ref, BuildContext context) async {
    final success =
        await ref.read(userCollectionsProvider.notifier).refresh(type);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('刷新失败，请稍后重试')),
      );
    }
  }

  void _onLoadMore(WidgetRef ref) {
    ref.read(userCollectionsProvider.notifier).loadMore(type);
  }

  bool _shouldTriggerLoadMore(ScrollMetrics metrics) {
    return metrics.pixels >= metrics.maxScrollExtent - _loadMoreTriggerDistance ||
        metrics.maxScrollExtent <= _loadMoreTriggerDistance;
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const minItemWidth = 320.0;
    if (width < 450) return 1;
    return (width / minItemWidth).floor().clamp(1, 4);
  }

  double _calculateHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final centeredPadding = (width - LayoutConstant.maxWidth) / 2;
    return centeredPadding > _minHorizontalPadding
        ? centeredPadding
        : _minHorizontalPadding;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(
      userCollectionsProvider.select((state) => state.tabState(type)),
    );
    final collectionsItem = tabState.data;

    return Builder(
      builder: (BuildContext context) {
        final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
        final horizontalPadding = _calculateHorizontalPadding(context);

        return RefreshIndicator(
          key: refreshIndicatorKey,
          onRefresh: () => _onRefresh(ref, context),
          edgeOffset: _refreshIndicatorOffset,
          displacement: _refreshIndicatorOffset + 16,
          notificationPredicate: (notification) =>
              notification.depth == 0 &&
              notification.metrics.axis == Axis.vertical,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification ||
                  notification is ScrollMetricsNotification ||
                  notification is ScrollEndNotification) {
                final metrics = notification.metrics;
                if (_shouldTriggerLoadMore(metrics) &&
                    collectionsItem != null &&
                    collectionsItem.data.isNotEmpty &&
                    tabState.canLoadMore &&
                    !tabState.isLoadingMore) {
                  _onLoadMore(ref);
                }
              }
              return false;
            },
            child: CustomScrollView(
              key: PageStorageKey<int>(type),
              scrollBehavior: const ScrollBehavior().copyWith(
                scrollbars: false,
              ),
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverOverlapInjector(handle: handle),
                if (collectionsItem == null &&
                    tabState.initialErrorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tabState.initialErrorMessage!),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => _onRefresh(ref, context),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (collectionsItem == null)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (collectionsItem.data.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('暂无数据')),
                  )
                else ...[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      10,
                      horizontalPadding,
                      10,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _calculateCrossAxisCount(context),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final collection = collectionsItem.data[index];
                          final displayName = (collection.nameCN == null ||
                                  collection.nameCN!.isEmpty)
                              ? collection.name
                              : collection.nameCN!;
                          return InkWell(
                            onTap: () {
                              AnimeInfoRoute.fromExtra(InfoRouteExtra(
                                id: collection.id,
                                name: displayName,
                                image: collection.images.large,
                              )).push(context);
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 2 / 3,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(12)),
                                    child: SizedBox(
                                      child: AnimationNetworkImage(
                                        url: collection.images.large,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                displayName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const InkWell(
                                              child: Icon(
                                                  Icons.expand_more_outlined),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            RankingView(
                                                ranking:
                                                    collection.rating.rank),
                                            if (collection.rating.score >
                                                0) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  StarView(
                                                      iconSize: 16,
                                                      score: collection
                                                          .rating.score),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${collection.rating.score}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: collectionsItem.data.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    sliver: SliverToBoxAdapter(
                      child: _CollectionFooter(
                        isLoadingMore: tabState.isLoadingMore,
                        hasMore: tabState.canLoadMore,
                        errorMessage: tabState.loadMoreErrorMessage,
                        onRetry: () => _onLoadMore(ref),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CollectionFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _CollectionFooter({
    required this.isLoadingMore,
    required this.hasMore,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(errorMessage!),
              TextButton(
                onPressed: onRetry,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('没有更多了'),
        ),
      );
    }

    return const SizedBox(height: 16);
  }
}

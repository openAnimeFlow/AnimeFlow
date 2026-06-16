import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/models/item/bangumi/user_collections_item.dart';
import 'package:anime_flow/routes/model/info_route_extra.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/ranking.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';

class CollectionTabView extends StatelessWidget {
  final TabController tabController;
  final List<String> tabs;
  final Function(int) onLoadMore;
  final Function(int) onRefresh;
  final Set<int> loadingMoreTypes;
  final Map<int, UserCollectionsItem?> collectionsCache;
  final Map<int, bool> hasMore;
  final Map<int, String?> initialErrorMessages;
  final Map<int, String?> loadMoreErrorMessages;
  final Map<int, GlobalKey<RefreshIndicatorState>> refreshIndicatorKeys;

  const CollectionTabView(
      {super.key,
      required this.collectionsCache,
      required this.tabController,
      required this.tabs,
      required this.onLoadMore,
      required this.onRefresh,
      required this.loadingMoreTypes,
      required this.hasMore,
      required this.initialErrorMessages,
      required this.loadMoreErrorMessages,
      required this.refreshIndicatorKeys});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: List.generate(tabs.length, (tabIndex) {
        final type = tabIndex + 1;
        return _CollectionTabView(
          key: PageStorageKey<int>(type),
          type: type,
          collectionsItem: collectionsCache[type],
          initialErrorMessage: initialErrorMessages[type],
          loadMoreErrorMessage: loadMoreErrorMessages[type],
          isLoadingMore: loadingMoreTypes.contains(type),
          hasMore: hasMore[type] ?? true,
          refreshIndicatorKey: refreshIndicatorKeys[type]!,
          onLoadMore: () => onLoadMore(type),
          onRefresh: () => onRefresh(type),
        );
      }),
    );
  }
}

class _CollectionTabView extends StatefulWidget {
  final int type;
  final UserCollectionsItem? collectionsItem;
  final String? initialErrorMessage;
  final String? loadMoreErrorMessage;
  final bool isLoadingMore;
  final bool hasMore;
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;

  const _CollectionTabView({
    super.key,
    required this.type,
    required this.collectionsItem,
    required this.initialErrorMessage,
    required this.loadMoreErrorMessage,
    required this.isLoadingMore,
    required this.hasMore,
    required this.refreshIndicatorKey,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  State<_CollectionTabView> createState() => __CollectionTabViewState();
}

class __CollectionTabViewState extends State<_CollectionTabView> {
  static const double _refreshIndicatorOffset =
      kToolbarHeight + kTextTabBarHeight;
  static const double _minHorizontalPadding = 10;
  static const double _loadMoreTriggerDistance = 200;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scheduleLoadMoreIfShortContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CollectionTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCount = oldWidget.collectionsItem?.data.length ?? 0;
    final newCount = widget.collectionsItem?.data.length ?? 0;
    if (oldCount != newCount ||
        oldWidget.isLoadingMore != widget.isLoadingMore ||
        oldWidget.hasMore != widget.hasMore) {
      _scheduleLoadMoreIfShortContent();
    }
  }

  void _scheduleLoadMoreIfShortContent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMoreIfContentDoesNotFillViewport();
    });
  }

  void _loadMoreIfContentDoesNotFillViewport() {
    if (!widget.hasMore || widget.isLoadingMore) {
      return;
    }
    if (widget.collectionsItem == null || widget.collectionsItem!.data.isEmpty) {
      return;
    }

    final scrollPosition = _scrollController.hasClients
        ? _scrollController.position
        : null;
    if (scrollPosition == null || !scrollPosition.hasContentDimensions) {
      return;
    }

    if (scrollPosition.maxScrollExtent <= _loadMoreTriggerDistance) {
      widget.onLoadMore();
    }
  }

  bool _shouldTriggerLoadMore(ScrollMetrics metrics) {
    return metrics.pixels >= metrics.maxScrollExtent - _loadMoreTriggerDistance;
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
  Widget build(BuildContext context) {
    if (widget.collectionsItem == null) {
      if (widget.initialErrorMessage != null) {
        return _buildPlaceholder(
          context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.initialErrorMessage!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: widget.onRefresh,
                child: const Text('重试'),
              ),
            ],
          ),
        );
      }

      return Builder(
        builder: (context) {
          final handle =
              NestedScrollView.sliverOverlapAbsorberHandleFor(context);
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverOverlapInjector(handle: handle),
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          );
        },
      );
    }

    if (widget.collectionsItem!.data.isEmpty) {
      return _buildPlaceholder(
        context,
        child: RefreshIndicator(
          key: widget.refreshIndicatorKey,
          onRefresh: widget.onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 320,
                child: Center(
                  child: Text('暂无数据'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final collections = widget.collectionsItem!.data;
    return Builder(
      builder: (context) {
        final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
        final horizontalPadding = _calculateHorizontalPadding(context);
        return RefreshIndicator(
          key: widget.refreshIndicatorKey,
          onRefresh: widget.onRefresh,
          edgeOffset: _refreshIndicatorOffset,
          displacement: _refreshIndicatorOffset + 16,
          notificationPredicate: (notification) =>
              notification.depth == 0 &&
              notification.metrics.axis == Axis.vertical,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification ||
                  notification is ScrollMetricsNotification) {
                final metrics = notification.metrics;
                if (_shouldTriggerLoadMore(metrics) &&
                    collections.isNotEmpty &&
                    widget.hasMore &&
                    !widget.isLoadingMore) {
                  widget.onLoadMore();
                }
              }
              return false;
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverOverlapInjector(handle: handle),
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
                        final collection = collections[index];
                        final displayName =
                            (collection.nameCN == null || collection.nameCN!.isEmpty)
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
                              // 左侧封面
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

                              // 右侧信息
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
                                              overflow:
                                                  TextOverflow.ellipsis,
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
                      childCount: collections.length,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverToBoxAdapter(
                    child: _CollectionFooter(
                      isLoadingMore: widget.isLoadingMore,
                      hasMore: widget.hasMore,
                      errorMessage: widget.loadMoreErrorMessage,
                      onRetry: widget.onLoadMore,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context, {required Widget child}) {
    return Builder(
      builder: (context) {
        final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: <Widget>[
            SliverOverlapInjector(handle: handle),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: child),
            ),
          ],
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

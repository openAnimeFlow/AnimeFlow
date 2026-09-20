import 'package:anime_flow/shared/models/flow/collection_update_result.dart';
import 'package:anime_flow/shared/widgets/collection_save_notice.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/features/user/presentation/providers/user_collection_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_collection_state.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/collection_button.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/shared/widgets/ranking.dart';
import 'package:anime_flow/shared/widgets/star.dart';
import 'package:anime_flow/shared/widgets/no_more_indicator.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

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
  static const int _pageSize = 20;

  void _scheduleLoadMoreIfNeeded(
    BuildContext context,
    WidgetRef ref,
    UserCollectionTabState tabState,
    UserCollectionsItem? collectionsItem,
  ) {
    if (collectionsItem == null ||
        collectionsItem.data.isEmpty ||
        collectionsItem.data.length >= _pageSize ||
        !tabState.canLoadMore ||
        tabState.isBusy ||
        tabState.loadMoreErrorMessage != null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final current = ref.read(userCollectionsProvider).tabState(type);
      if (current.data == null ||
          current.data!.data.isEmpty ||
          current.data!.data.length >= _pageSize ||
          !current.canLoadMore ||
          current.isBusy ||
          current.loadMoreErrorMessage != null) {
        return;
      }
      ref.read(userCollectionsProvider.notifier).loadMore(type);
    });
  }

  void _scheduleLoadMoreForMetrics(
    BuildContext context,
    WidgetRef ref,
    ScrollMetrics metrics,
    int depth,
  ) {
    if (depth != 0 ||
        metrics.axis != Axis.vertical ||
        !_shouldTriggerLoadMore(metrics)) {
      return;
    }
    // Metrics notifications may arrive during layout. Recheck live state
    // after the frame to guard against duplicate notifications and errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final current = ref.read(userCollectionsProvider).tabState(type);
      if (current.data == null ||
          current.data!.data.isEmpty ||
          !current.canLoadMore ||
          current.isBusy ||
          current.loadMoreErrorMessage != null) {
        return;
      }
      _onLoadMore(ref);
    });
  }

  Future<void> _onRefresh(WidgetRef ref, BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final success =
        await ref.read(userCollectionsProvider.notifier).refresh(type);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.refreshFailedRetry)),
      );
    }
  }

  void _onLoadMore(WidgetRef ref) {
    ref.read(userCollectionsProvider.notifier).loadMore(type);
  }

  bool _shouldTriggerLoadMore(ScrollMetrics metrics) {
    return metrics.pixels >=
            metrics.maxScrollExtent - _loadMoreTriggerDistance ||
        metrics.maxScrollExtent <= _loadMoreTriggerDistance;
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
    final l10n = AppLocalizations.of(context);
    final tabState = ref.watch(
      userCollectionsProvider.select((state) => state.tabState(type)),
    );
    final collectionsItem = tabState.data;
    _scheduleLoadMoreIfNeeded(context, ref, tabState, collectionsItem);
    final colorScheme = ColorScheme.of(context);

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
          child: NotificationListener<Notification>(
            onNotification: (notification) {
              if (notification is ScrollMetricsNotification) {
                _scheduleLoadMoreForMetrics(
                    context, ref, notification.metrics, notification.depth);
              } else if (notification is ScrollUpdateNotification ||
                  notification is ScrollEndNotification) {
                final scroll = notification as ScrollNotification;
                _scheduleLoadMoreForMetrics(
                    context, ref, scroll.metrics, scroll.depth);
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
                          Text(l10n.collectionLoadFailed),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => _onRefresh(ref, context),
                            child: Text(l10n.retry),
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
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: !tabState.canLoadMore
                          ? Text(l10n.noData)
                          : tabState.isBusy
                              ? const CircularProgressIndicator()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (tabState.loadMoreErrorMessage !=
                                        null) ...[
                                      Text(l10n.collectionLoadMoreFailed),
                                      const SizedBox(height: 12),
                                    ],
                                    FilledButton.icon(
                                      onPressed: () => _onLoadMore(ref),
                                      label: Text(
                                        tabState.loadMoreErrorMessage == null
                                            ? l10n.viewMore
                                            : l10n.retry,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 10,
                    ),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth =
                            constraints.crossAxisExtent - horizontalPadding * 2;
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                (availableWidth / 320.0).floor().clamp(1, 4),
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
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(12)),
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
                                      child: AnimationNetworkImage(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(12)),
                                        url: collection.images.large,
                                        fit: BoxFit.cover,
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (['PENDING', 'AUTH_REQUIRED', 'CONFLICT']
                                                    .contains(collection.interest.remoteSyncStatus))
                                                  Tooltip(
                                                    message: collectionSaveMessage(l10n,
                                                      CollectionRemoteSyncStatus.parse(collection.interest.remoteSyncStatus)),
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(8),
                                                      child: Icon(Icons.cloud_off_outlined, size: 18),
                                                    ),
                                                  ),
                                                CollectionButton(
                                                  key: ValueKey(collection.id),
                                                  collectType:
                                                      collectTypeFromApiType(
                                                    collection.interest.type,
                                                  ),
                                                  buttonBuilder: (context,
                                                      label,
                                                      icon,
                                                      onPressed,
                                                      isOpen) {
                                                    return IconButton(
                                                      tooltip: label,
                                                      onPressed: onPressed,
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                        minWidth: 40,
                                                        minHeight: 40,
                                                      ),
                                                      icon: AnimatedRotation(
                                                        turns: isOpen ? 0.5 : 0,
                                                        duration:
                                                            const Duration(
                                                          milliseconds: 180,
                                                        ),
                                                        curve:
                                                            Curves.easeOutCubic,
                                                        child: const Icon(Icons
                                                            .expand_more_outlined),
                                                      ),
                                                    );
                                                  },
                                                  onCollectTypeChanged:
                                                      (newType) async {
                                                    try {
                                                      final result = await ref
                                                          .read(
                                                              userCollectionsProvider
                                                                  .notifier)
                                                          .updateCollectionType(
                                                            collection,
                                                            newType.value,
                                                          );
                                                      if (context.mounted) {
                                                        showCollectionSaveNotice(context, result);
                                                      }
                                                    } on AnimeFlowApiException catch (e) {
                                                      NotificationToast.show(
                                                        e.message,
                                                        title:
                                                            l10n.updateFailed,
                                                      );
                                                      rethrow;
                                                    } catch (e) {
                                                      NotificationToast.show(
                                                        e.toString(),
                                                        title:
                                                            l10n.updateFailed,
                                                      );
                                                      rethrow;
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                            Text(
                                              collection.info,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: colorScheme
                                                      .onSurfaceVariant
                                                      .withValues(alpha: 0.8)),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                                                          color:
                                                              Colors.grey[600],
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
                        );
                      },
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
    final l10n = AppLocalizations.of(context);
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
              Text(l10n.collectionLoadMoreFailed),
              TextButton(
                onPressed: onRetry,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasMore) {
      return const NoMoreIndicator(
        padding: EdgeInsets.symmetric(vertical: 16),
      );
    }

    return const SizedBox(height: 16);
  }
}

import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';

/// 单个收藏 Tab 的分页与加载状态。
class UserCollectionTabState {
  final UserCollectionsItem? data;
  final int offset;
  final bool? hasMore;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? initialErrorMessage;
  final String? loadMoreErrorMessage;
  final String? keyword;
  final int requestVersion;

  const UserCollectionTabState({
    this.data,
    this.offset = 0,
    this.hasMore,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.initialErrorMessage,
    this.loadMoreErrorMessage,
    this.keyword,
    this.requestVersion = 0,
  });

  bool get isBusy => isInitialLoading || isRefreshing || isLoadingMore;

  bool get canLoadMore => hasMore ?? true;

  UserCollectionTabState copyWith({
    UserCollectionsItem? data,
    int? offset,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? initialErrorMessage,
    String? loadMoreErrorMessage,
    String? keyword,
    int? requestVersion,
    bool clearData = false,
    bool clearHasMore = false,
    bool clearKeyword = false,
    bool clearInitialErrorMessage = false,
    bool clearLoadMoreErrorMessage = false,
  }) {
    return UserCollectionTabState(
      data: clearData ? null : (data ?? this.data),
      offset: offset ?? this.offset,
      hasMore: clearHasMore ? null : (hasMore ?? this.hasMore),
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      initialErrorMessage: clearInitialErrorMessage
          ? null
          : (initialErrorMessage ?? this.initialErrorMessage),
      loadMoreErrorMessage: clearLoadMoreErrorMessage
          ? null
          : (loadMoreErrorMessage ?? this.loadMoreErrorMessage),
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      requestVersion: requestVersion ?? this.requestVersion,
    );
  }
}

/// 五个收藏 Tab 的聚合状态。
class UserCollectionsState {
  final Map<int, UserCollectionTabState> tabs;

  const UserCollectionsState({this.tabs = const {}});

  UserCollectionTabState tabState(int type) =>
      tabs[type] ?? const UserCollectionTabState();

  UserCollectionsState updateTab(
    int type,
    UserCollectionTabState Function(UserCollectionTabState current) updater,
  ) {
    return UserCollectionsState(
      tabs: {...tabs, type: updater(tabState(type))},
    );
  }

  UserCollectionsState moveCollection(
    UserCollectionData collection,
    int newType, {
    required int destinationTotal,
    int sourceTotal = 0,
  }) {
    final oldType = collection.interest.type;
    if (oldType == newType) return this;
    final json = collection.toJson();
    json['interest'] = {
      ...collection.interest.toJson(),
      'type': newType,
      'updatedAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    final updated = UserCollectionData.fromJson(json);
    var result = this;
    for (final type in {if (oldType >= 1 && oldType <= 5) oldType, newType}) {
      result = result.updateTab(type, (tab) {
        final keyword = tab.keyword?.trim().toLowerCase() ?? '';
        final matches = keyword.isEmpty ||
            collection.name.toLowerCase().contains(keyword) ||
            (collection.nameCN?.toLowerCase().contains(keyword) ?? false);
        final items = [...?tab.data?.data];
        final removed = items.where((item) => item.id == collection.id).length;
        items.removeWhere((item) => item.id == collection.id);
        final insert = type == newType && matches;
        if (insert) items.insert(0, updated);
        final delta = (insert ? 1 : 0) - removed;
        final total = tab.data == null
            ? (type == newType ? destinationTotal : sourceTotal)
            : (tab.data!.total +
                    (type == oldType
                        ? (matches ? -1 : 0)
                        : (insert && removed == 0 ? 1 : 0)))
                .clamp(0, 1 << 31);
        return tab.copyWith(
          data: UserCollectionsItem(data: items, total: total),
          offset: (tab.offset + delta).clamp(0, 1 << 31),
          hasMore: tab.data == null
              ? items.length < total
              : tab.canLoadMore && items.length < total,
          requestVersion: tab.requestVersion + 1,
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          clearInitialErrorMessage: true,
          clearLoadMoreErrorMessage: true,
        );
      });
    }
    return result;
  }
}

const userCollectionTypeLabels = ['想看', '看过', '在看', '搁置', '抛弃'];

import 'package:anime_flow/models/item/bangumi/user_collections_item.dart';

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
}

const userCollectionTypeLabels = ['想看', '看过', '在看', '搁置', '抛弃'];

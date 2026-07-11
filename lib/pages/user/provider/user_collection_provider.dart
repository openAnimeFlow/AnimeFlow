import 'package:anime_flow/models/item/bangumi/user_collections_item.dart';
import 'package:anime_flow/models/item/flow/flow_users.dart';
import 'package:anime_flow/network/api/flow_api.dart';
import 'package:anime_flow/pages/user/provider/user_collection_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_collection_provider.g.dart';

const _pageSize = 20;

@Riverpod(keepAlive: true)
class UserCollections extends _$UserCollections {
  @override
  UserCollectionsState build() {
    return const UserCollectionsState();
  }

  void reset() {
    state = const UserCollectionsState();
  }

  Future<void> loadInitial(int type) => _load(type);

  Future<void> loadMore(int type) => _load(type, loadMore: true);

  Future<void> search(int type, String keyword) async {
    final normalizedKeyword = keyword.trim();
    state = state.updateTab(
      type,
      (current) => current.copyWith(
        offset: 0,
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        keyword: normalizedKeyword.isEmpty ? null : normalizedKeyword,
        requestVersion: current.requestVersion + 1,
        clearData: true,
        clearHasMore: true,
        clearKeyword: normalizedKeyword.isEmpty,
        clearInitialErrorMessage: true,
        clearLoadMoreErrorMessage: true,
      ),
    );
    await _load(type);
  }

  /// 下拉刷新；若刷新前已有缓存且请求失败，返回 `false` 以便 UI 提示。
  Future<bool> refresh(int type) async {
    final hadCache = state.tabState(type).data != null;
    final failed = await _load(type, refresh: true);
    if (failed && hadCache) {
      return false;
    }
    return true;
  }

  bool isTypeBusy(int type) => state.tabState(type).isBusy;

  Future<UserCollectionsItem> _fetchPage({
    required int type,
    required int offset,
    String? keyword,
  }) {
    return FlowApi.myCollectionsService(
      type: type,
      limit: _pageSize,
      offset: offset,
      keyword: keyword,
    );
  }

  Future<bool> _load(
    int type, {
    bool loadMore = false,
    bool refresh = false,
  }) async {
    final tab = state.tabState(type);
    final requestVersion = tab.requestVersion;
    final keyword = tab.keyword;
    if (tab.isBusy) {
      return false;
    }
    if (loadMore && !tab.canLoadMore) {
      return false;
    }
    if (!loadMore && !refresh && tab.data != null) {
      return false;
    }

    state = state.updateTab(type, (current) {
      if (loadMore) {
        return current.copyWith(
          isLoadingMore: true,
          clearLoadMoreErrorMessage: true,
        );
      }
      if (refresh) {
        return current.copyWith(
          isRefreshing: true,
          clearLoadMoreErrorMessage: true,
        );
      }
      return current.copyWith(
        isInitialLoading: true,
        clearInitialErrorMessage: true,
      );
    });

    var refreshFailedWithCache = false;
    try {
      final offset = loadMore && !refresh ? tab.offset : 0;
      final page = await _fetchPage(
        type: type,
        offset: offset,
        keyword: keyword,
      );
      if (state.tabState(type).requestVersion != requestVersion) {
        return false;
      }

      state = state.updateTab(type, (current) {
        final data = loadMore && !refresh && current.data != null
            ? UserCollectionsItem(
                data: [...current.data!.data, ...page.data],
                total: page.total,
              )
            : page;
        final newOffset = loadMore && !refresh && current.data != null
            ? offset + page.data.length
            : page.data.length;
        final loadedCount = data.data.length;

        return current.copyWith(
          data: data,
          offset: newOffset,
          hasMore: page.data.length == _pageSize && loadedCount < page.total,
          clearInitialErrorMessage: true,
          clearLoadMoreErrorMessage: true,
        );
      });
    } catch (_) {
      if (state.tabState(type).requestVersion != requestVersion) {
        return false;
      }
      refreshFailedWithCache = refresh && state.tabState(type).data != null;
      state = state.updateTab(type, (current) {
        if (loadMore && current.data != null) {
          return current.copyWith(
            loadMoreErrorMessage: '加载更多失败，请稍后重试',
          );
        }
        if (current.data == null) {
          return current.copyWith(
            initialErrorMessage: '加载失败，请稍后重试',
          );
        }
        return current;
      });
    } finally {
      if (state.tabState(type).requestVersion == requestVersion) {
        state = state.updateTab(
          type,
          (current) => current.copyWith(
            isInitialLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
          ),
        );
      }
    }

    return refreshFailedWithCache;
  }
}

List<String> buildUserCollectionTabLabels(FlowUsers user) {
  return userCollectionTypeLabels.asMap().entries.map((entry) {
    final type = entry.key + 1;
    final total = user.collectionCounts.countForType(type);
    return '${entry.value}\n$total';
  }).toList();
}

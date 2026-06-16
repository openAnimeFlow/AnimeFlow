import 'package:anime_flow/models/item/flow/flow_users.dart';
import 'package:anime_flow/pages/user/provider/user_collection_state.dart';
import 'package:anime_flow/pages/user/service/user_collection_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_collection_provider.g.dart';

@Riverpod(keepAlive: true)
class UserCollections extends _$UserCollections {
  late final UserCollectionService _service;

  @override
  UserCollectionsState build() {
    _service = UserCollectionService();
    return const UserCollectionsState();
  }

  void reset() {
    state = const UserCollectionsState();
  }

  Future<void> loadInitial(int type) => _load(type);

  Future<void> loadMore(int type) => _load(type, loadMore: true);

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

  Future<bool> _load(
    int type, {
    bool loadMore = false,
    bool refresh = false,
  }) async {
    final tab = state.tabState(type);
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
      final offset =
          loadMore && !refresh ? tab.offset : 0;
      final page = await _service.fetchPage(type: type, offset: offset);

      state = state.updateTab(type, (current) {
        final data = loadMore && !refresh && current.data != null
            ? _service.mergeLoadMore(cached: current.data!, page: page)
            : page;
        final newOffset = loadMore && !refresh && current.data != null
            ? offset + page.data.length
            : page.data.length;

        return current.copyWith(
          data: data,
          offset: newOffset,
          hasMore: _service.hasMoreAfterFetch(
            page: page,
            loadedCount: data.data.length,
          ),
          clearInitialErrorMessage: true,
          clearLoadMoreErrorMessage: true,
        );
      });
    } catch (_) {
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
      state = state.updateTab(
        type,
        (current) => current.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
        ),
      );
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

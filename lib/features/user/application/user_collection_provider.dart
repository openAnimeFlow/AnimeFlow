import 'dart:async';

import 'collection_revision_provider.dart';
import 'collection_refresh_provider.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/shared/models/flow/collection_update_result.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:anime_flow/shared/models/enums/collection_sort.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/user/application/user_collection_state.dart';
import 'package:anime_flow/features/user/application/user_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;

part 'user_collection_provider.g.dart';

const _pageSize = 20;

typedef CollectionEvaluation = Future<CollectionUpdateResult> Function(
  int subjectId, {
  int? type,
  required int rate,
  required List<String> tags,
  required String comment,
  required int subjectType,
});

final collectionEvaluationProvider = Provider<CollectionEvaluation>((ref) {
  return (subjectId,
      {type,
      required rate,
      required tags,
      required comment,
      required subjectType}) async {
    final session = ref.read(currentFlowTokenProvider).value?.sessionId;
    final result = await FlowApi.updateCollectionService(subjectId,
        type: type,
        rate: rate,
        tags: tags,
        comment: comment,
        subjectType: subjectType);
    if (ref.mounted &&
        ref.read(currentFlowTokenProvider).value?.sessionId == session) {
      ref.read(collectionRevisionProvider.notifier).changed();
    }
    return result;
  };
});

typedef CollectionPageLoader = Future<UserCollectionsItem> Function({
  required int type,
  required int offset,
  required CollectionSort sort,
  String? keyword,
});

final collectionCancelProvider = Provider<Future<void> Function(int)>((ref) {
  return (subjectId) async {
    await FlowApi.cancelCollectionService(subjectId);
    ref.read(collectionRevisionProvider.notifier).changed();
  };
});

final collectionPageLoaderProvider = Provider<CollectionPageLoader>((ref) {
  return ({required type, required offset, required sort, keyword}) =>
      FlowApi.myCollectionsService(
        type: type,
        limit: _pageSize,
        offset: offset,
        keyword: keyword,
        sort: sort,
      );
});

final collectionTypeUpdateProvider =
    Provider<Future<CollectionUpdateResult> Function(UserCollectionData, int)>(
        (ref) {
  return (collection, newType) async {
    final result = await FlowApi.updateCollectionService(
      collection.id,
      type: newType,
      subjectType: collection.type,
    );
    ref.read(collectionRevisionProvider.notifier).changed();
    return result;
  };
});

@Riverpod(keepAlive: true)
class UserCollections extends _$UserCollections {
  Object _session = Object();

  @override
  UserCollectionsState build() {
    _session = Object();
    ref.listen(authSessionRevisionProvider, (previous, next) => reset());
    ref.listen(collectionRefreshProvider, (previous, next) => reset());
    ref.onDispose(() => _session = Object());
    return const UserCollectionsState();
  }

  void reset() {
    _session = Object();
    state = const UserCollectionsState();
  }

  Future<void> loadInitial(int type) => _load(type);

  Future<void> loadMore(int type) => _load(type, loadMore: true);

  Future<CollectionUpdateResult?> updateCollectionType(
    UserCollectionData collection,
    int newType,
  ) async {
    // Use the state shown by the caller. Cached tabs may predate a fresh
    // detail response and must not suppress the user's requested update.

    final session = _session;
    if (newType == 0) {
      await ref.read(collectionCancelProvider)(collection.id);
      if (!ref.mounted || session != _session) return null;
      final loadingTypes = state.tabs.entries
          .where((entry) => entry.value.data == null && entry.value.isBusy)
          .map((entry) => entry.key)
          .toList();
      state = state.removeCollection(collection);
      for (final type in loadingTypes) {
        unawaited(loadInitial(type));
      }
      ref
          .read(currentUserInfoProvider.notifier)
          .moveCollectionCount(collection.interest.type, 0);
      return null;
    }
    final result =
        await ref.read(collectionTypeUpdateProvider)(collection, newType);
    if (!ref.mounted || session != _session) return null;
    if (collection.interest.type == newType) {
      await refresh(newType);
      return ref.mounted && session == _session ? result : null;
    }
    final updatedJson = collection.toJson();
    updatedJson['interest'] = {
      ...collection.interest.toJson(),
      'remoteSyncStatus': result.remoteSyncStatus.apiValue,
    };
    final counts =
        ref.read(currentUserInfoProvider).asData?.value?.collectionCounts;
    state = state.moveCollection(
      UserCollectionData.fromJson(updatedJson),
      newType,
      destinationTotal:
          counts == null ? null : counts.countForType(newType) + 1,
      sourceTotal: counts == null
          ? null
          : (counts.countForType(collection.interest.type) - 1)
              .clamp(0, 1 << 31),
    );
    ref
        .read(currentUserInfoProvider.notifier)
        .moveCollectionCount(collection.interest.type, newType);
    return result;
  }

  Future<void> applyFilters(
    int type, {
    required String keyword,
    required CollectionSort sort,
  }) async {
    final normalizedKeyword = keyword.trim();
    final session = _session;
    state = state.updateTab(
      type,
      (current) => current.copyWith(
        offset: 0,
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        keyword: normalizedKeyword.isEmpty ? null : normalizedKeyword,
        sort: sort,
        requestVersion: current.requestVersion + 1,
        clearData: true,
        clearHasMore: true,
        clearKeyword: normalizedKeyword.isEmpty,
        clearInitialErrorMessage: true,
        clearLoadMoreErrorMessage: true,
      ),
    );
    final requestVersion = state.tabState(type).requestVersion;
    await AppSettings.setCollectionSort(type, sort);
    if (!ref.mounted ||
        session != _session ||
        state.tabState(type).requestVersion != requestVersion) {
      return;
    }
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
    required CollectionSort sort,
    String? keyword,
  }) {
    return ref.read(collectionPageLoaderProvider)(
      type: type,
      offset: offset,
      keyword: keyword,
      sort: sort,
    );
  }

  Future<bool> _load(
    int type, {
    bool loadMore = false,
    bool refresh = false,
  }) async {
    var tab = state.tabState(type);
    final sort = AppSettings.getCollectionSort(type);
    if (tab.sort != sort) {
      // 持久化排序变化时从第一页重载，避免混合不同排序的分页缓存。
      state = state.updateTab(
        type,
        (current) => current.copyWith(
          sort: sort,
          offset: 0,
          requestVersion: current.requestVersion + 1,
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          clearData: true,
          clearHasMore: true,
          clearInitialErrorMessage: true,
          clearLoadMoreErrorMessage: true,
        ),
      );
      tab = state.tabState(type);
      loadMore = false;
      refresh = false;
    }
    final session = _session;
    final requestVersion = tab.requestVersion;
    bool isCurrentRequest() =>
        ref.mounted &&
        session == _session &&
        state.tabState(type).requestVersion == requestVersion;
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
        sort: sort,
      );
      if (!isCurrentRequest()) {
        return false;
      }

      state = state.updateTab(type, (current) {
        final data = loadMore && !refresh && current.data != null
            ? UserCollectionsItem(
                data: _mergeCollectionPages(current.data!.data, page.data),
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
          hasKnownTotal: true,
          hasMore: page.data.length == _pageSize && loadedCount < page.total,
          clearInitialErrorMessage: true,
          clearLoadMoreErrorMessage: true,
        );
      });
    } catch (_) {
      if (!isCurrentRequest()) {
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
      if (isCurrentRequest()) {
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

List<UserCollectionData> _mergeCollectionPages(
  List<UserCollectionData> current,
  List<UserCollectionData> next,
) {
  final merged = <int, UserCollectionData>{
    for (final item in current) item.id: item,
  };
  for (final item in next) {
    merged.putIfAbsent(item.id, () => item);
  }
  return merged.values.toList(growable: false);
}

List<String> buildUserCollectionTabLabels(
  FlowUsers user,
  List<String> localizedLabels,
) {
  return localizedLabels.asMap().entries.map((entry) {
    final type = entry.key + 1;
    final total = user.collectionCounts.countForType(type);
    return '${entry.value}\n$total';
  }).toList();
}

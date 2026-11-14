import 'package:anime_flow/core/cache/json_response_cache.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/shared/models/bangumi/hot_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'popular_anime_repository.g.dart';

@Riverpod(keepAlive: true)
class PopularAnimeRepository extends _$PopularAnimeRepository {
  @override
  void build() {}

  int _generation = 0;
  Future<void> _cacheReady = Future.value();

  CachedJsonResponse<HotItem>? readPage(
      {required int limit, required int offset}) {
    return JsonResponseCache.read(Storage.popularAnimeCache, '$limit:$offset',
        fromJson: HotItem.fromJson);
  }

  Future<HotItem> getPage({
    required int limit,
    required int offset,
    CancelToken? cancelToken,
    bool forceRefresh = false,
    bool fallbackToCache = true,
  }) async {
    while (true) {
      await _cacheReady;
      if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
      var generation = _generation;
      bool isCurrent() => generation == _generation;
      try {
        final result = await JsonResponseCache.get(
          Storage.popularAnimeCache,
          '$limit:$offset',
          load: () async {
            final page = await FlowApi.getHotService(limit, offset,
                cancelToken: cancelToken);
            if (cancelToken?.isCancelled ?? false) {
              throw cancelToken!.cancelError!;
            }
            // 首页成功刷新后移除旧排名的分页，失败时仍保留离线缓存。
            if (offset == 0 && isCurrent()) {
              generation = await _invalidateCache();
            }
            return page;
          },
          fromJson: HotItem.fromJson,
          toJson: (item) => item.toJson(),
          cancelToken: cancelToken,
          forceRefresh: forceRefresh,
          fallbackToCache: fallbackToCache,
          maxEntries: 20,
          shouldCache: isCurrent,
        );
        if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
        if (isCurrent()) return result;
      } catch (_) {
        if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
        if (isCurrent()) rethrow;
      }
    }
  }

  Future<int> _invalidateCache() {
    final generation = ++_generation;
    _cacheReady = _cacheReady.then((_) async {
      await Storage.popularAnimeCache.clear();
    }).catchError((Object error) {
      debugPrint('Failed to clear popular anime cache: $error');
    });
    return _cacheReady.then((_) => generation);
  }
}

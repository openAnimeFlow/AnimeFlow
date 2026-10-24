import 'dart:convert';

import 'package:anime_flow/core/cache/json_response_cache.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/user/user_events.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subject_episodes_repository.g.dart';

/// 按会话保存剧集分页，避免不同账号的观看状态相互覆盖。
@Riverpod(keepAlive: true)
class SubjectEpisodesRepository extends _$SubjectEpisodesRepository {
  final _generations = <String, int>{};
  Future<void> _cacheReady = Future.value();
  int _revision = 0;

  @override
  void build() {
    ref.listen(collectionRevisionProvider, (_, __) {
      _revision++;
      _cacheReady = _cacheReady
          .then((_) => JsonResponseCache.clear(Storage.subjectEpisodesCache))
          .catchError((Object error) {
        debugPrint('清理剧集缓存失败：$error');
      });
    });
  }

  String _prefix(int subjectId, String? sessionId) =>
      '${jsonEncode([sessionId, subjectId])}:';

  Future<CachedJsonResponse<EpisodesItem>?> readPage(
    int subjectId, {
    required String? sessionId,
    required int limit,
    required int offset,
  }) async {
    await _cacheReady;
    return JsonResponseCache.read(
      Storage.subjectEpisodesCache,
      '${_prefix(subjectId, sessionId)}$limit:$offset',
      fromJson: EpisodesItem.fromJson,
    );
  }

  Future<EpisodesItem> getPage(
    int subjectId, {
    required String? sessionId,
    required int limit,
    required int offset,
    required CancelToken cancelToken,
    bool forceRefresh = false,
    bool fallbackToCache = true,
  }) async {
    final prefix = _prefix(subjectId, sessionId);
    while (true) {
      await _cacheReady;
      if (cancelToken.isCancelled) throw cancelToken.cancelError!;
      final revision = _revision;
      var generation = _generations[prefix] ?? 0;
      bool isCurrent() =>
          revision == _revision && generation == (_generations[prefix] ?? 0);
      if (!forceRefresh) {
        final cached = JsonResponseCache.read(
          Storage.subjectEpisodesCache,
          '$prefix$limit:$offset',
          fromJson: EpisodesItem.fromJson,
        );
        // 过期页仍可立即展示，由首页后台刷新统一切换分页版本。
        if (cached != null) return cached.data;
      }
      try {
        final result = await JsonResponseCache.get(
          Storage.subjectEpisodesCache,
          '$prefix$limit:$offset',
          load: () async {
            final page = await FlowApi.getSubjectEpisodesByIdService(
              subjectId,
              limit,
              offset,
              cancelToken: cancelToken,
            );
            if (cancelToken.isCancelled) throw cancelToken.cancelError!;
            // 首页刷新成功后才清理旧页，避免页边界变化后混入旧分页。
            if (offset == 0 && isCurrent()) {
              generation = await _invalidatePages(prefix);
            }
            return page;
          },
          fromJson: EpisodesItem.fromJson,
          toJson: (page) => page.toJson(),
          cancelToken: cancelToken,
          forceRefresh: forceRefresh,
          fallbackToCache: fallbackToCache,
          shouldCache: isCurrent,
        );
        if (cancelToken.isCancelled) throw cancelToken.cancelError!;
        if (isCurrent()) return result;
      } catch (_) {
        if (cancelToken.isCancelled) throw cancelToken.cancelError!;
        if (isCurrent()) rethrow;
      }
      // 观看状态修改或缓存失效后，重新读取，避免旧响应写回页面。
    }
  }

  Future<int> _invalidatePages(String prefix) {
    final generation = (_generations[prefix] ?? 0) + 1;
    _generations[prefix] = generation;
    _cacheReady = _cacheReady.then((_) async {
      final box = Storage.subjectEpisodesCache;
      await box.deleteAll(box.keys
          .whereType<String>()
          .where((key) => key.startsWith(prefix))
          .toList());
    }).catchError((Object error) {
      debugPrint('清理条目剧集缓存失败：$error');
    });
    return _cacheReady.then((_) => generation);
  }

  Future<void> updateEpisodeWatched(
    int subjectId,
    int episodeId, {
    required String? sessionId,
    required bool watched,
  }) async {
    await FlowApi.updateEpisodeWatchedService(episodeId, watched: watched);
    await cacheWatched(subjectId,
        sessionId: sessionId, episodeId: episodeId, watched: watched);
  }

  Future<void> markAllEpisodesWatched(
    int subjectId, {
    required String? sessionId,
  }) async {
    await FlowApi.markAllEpisodesWatchedService(subjectId);
    await cacheWatched(subjectId, sessionId: sessionId, watched: true);
  }

  /// 同步所有已缓存页的观看状态，保留原过期时间，避免延长旧资料的有效期。
  Future<void> cacheWatched(
    int subjectId, {
    required String? sessionId,
    int? episodeId,
    required bool watched,
  }) {
    final prefix = _prefix(subjectId, sessionId);
    _generations[prefix] = (_generations[prefix] ?? 0) + 1;
    _cacheReady = _cacheReady.then((_) async {
      final box = Storage.subjectEpisodesCache;
      final updates = <String, String>{};
      for (final entry in box.toMap().entries) {
        if (entry.key is! String || !(entry.key as String).startsWith(prefix)) {
          continue;
        }
        try {
          final cached = jsonDecode(entry.value) as Map<String, dynamic>;
          final page = EpisodesItem.fromJson(cached['data']);
          cached['data'] = page
              .copyWith(
                  data: page.data
                      .map((episode) =>
                          episodeId == null || episode.id == episodeId
                              ? episode.copyWith(watched: watched)
                              : episode)
                      .toList())
              .toJson();
          updates[entry.key as String] = jsonEncode(cached);
        } catch (error) {
          debugPrint('更新剧集分页缓存失败：$error');
        }
      }
      await box.putAll(updates);
    }).catchError((Object error) {
      debugPrint('更新剧集缓存失败：$error');
    });
    return _cacheReady;
  }
}

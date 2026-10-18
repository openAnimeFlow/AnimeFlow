import 'dart:convert';

import 'package:anime_flow/core/cache/json_response_cache.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/anime_info/data/datasources/anime_info_local_data_source.dart';
import 'package:anime_flow/features/anime_info/data/datasources/anime_info_remote_data_source.dart';
import 'package:anime_flow/features/user/application/collection_revision_provider.dart';
import 'package:anime_flow/shared/models/bangumi/producers_item.dart';
import 'package:anime_flow/shared/models/bangumi/related_subjects_item.dart';
import 'package:anime_flow/shared/models/bangumi/subject_comments_item.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anime_info_repository.g.dart';

@Riverpod(keepAlive: true)
class AnimeInfoRepository extends _$AnimeInfoRepository {
  @override
  void build() {
    ref.listen(collectionRevisionProvider, (_, __) => invalidateCache());
  }

  final _local = AnimeInfoLocalDataSource();
  final _remote = AnimeInfoRemoteDataSource();
  Future<void> _cacheReady = Future.value();
  int _generation = 0;
  bool _cacheReadable = true;
  final _commentsGenerations = <int, int>{};
  Future<void> _commentsCacheReady = Future.value();

  /// 在下次读取前清空缓存，并阻止失效前发出的请求重新写入旧数据。
  void invalidateCache() {
    final generation = ++_generation;
    _cacheReadable = false;
    _cacheReady = _cacheReady.then((_) => _local.clear()).then((_) {
      if (generation == _generation) _cacheReadable = true;
    }).catchError(
      (Object error) => debugPrint('Failed to clear subject cache: $error'),
    );
  }

  /// 先返回缓存的条目详情，缓存过期时再异步请求并推送最新数据。
  Stream<SubjectsInfoItem> watchSubject(
    int subjectId, {
    required String? sessionId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async* {
    var hasCachedSubject = false;
    // 缓存失效不代表订阅已取消。仍在等待详情的页面需要重新加载，
    // 否则空流结束会使 StreamNotifier 一直停留在 AsyncLoading。
    while (true) {
      await _cacheReady;
      if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
      final generation = _generation;
      final cacheRevision =
          JsonResponseCache.revisionOf(Storage.animeInfoCache);
      if (!forceRefresh && _cacheReadable) {
        try {
          final cached = _local.read(subjectId, sessionId: sessionId);
          if (cached != null) {
            hasCachedSubject = true;
            yield cached.subject;
            if (cancelToken?.isCancelled ?? false) return;
            if (generation != _generation) continue;
            final age = DateTime.now().millisecondsSinceEpoch - cached.cachedAt;
            if (age >= 0 &&
                age < JsonResponseCache.defaultMaxAge.inMilliseconds) {
              return;
            }
          }
        } catch (error) {
          debugPrint('Failed to read subject cache: $error');
        }
      }
      if (cancelToken?.isCancelled ?? false) return;
      if (generation != _generation) continue;
      try {
        final subject =
            await _remote.getSubject(subjectId, cancelToken: cancelToken);
        if (cancelToken?.isCancelled ?? false) return;
        if (generation != _generation) continue;
        if (cacheRevision ==
            JsonResponseCache.revisionOf(Storage.animeInfoCache)) {
          await cacheSubject(subject, sessionId: sessionId);
        }
        if (cancelToken?.isCancelled ?? false) return;
        if (generation != _generation) continue;
        yield subject;
        return;
      } catch (error) {
        if (cancelToken?.isCancelled ?? false) return;
        if (generation != _generation) continue;
        if (!hasCachedSubject) rethrow;
        debugPrint('Failed to refresh subject cache: $error');
        return;
      }
    }
  }

  /// 缓存写入失败不影响已成功的请求或本地修改。
  Future<void> cacheSubject(
    SubjectsInfoItem subject, {
    required String? sessionId,
  }) async {
    final generation = _generation;
    final cacheRevision = JsonResponseCache.revisionOf(Storage.animeInfoCache);
    await _cacheReady;
    if (generation != _generation ||
        cacheRevision != JsonResponseCache.revisionOf(Storage.animeInfoCache)) {
      return;
    }
    try {
      await _local.write(subject, sessionId: sessionId);
    } catch (error) {
      debugPrint('Failed to write subject cache: $error');
    }
  }

  Future<List<String>> getStills(int subjectId, {CancelToken? cancelToken}) =>
      _remote.getStills(subjectId, cancelToken: cancelToken);

  Future<SubjectCommentItem> getComments(
    int subjectId, {
    required int limit,
    required int offset,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    while (true) {
      await _commentsCacheReady;
      if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
      var generation = _commentsGenerations[subjectId] ?? 0;
      bool isCurrent() => generation == (_commentsGenerations[subjectId] ?? 0);
      try {
        final result = await JsonResponseCache.get(
          Storage.subjectCommentsCache,
          '$subjectId:$limit:$offset',
          load: () async {
            final page = await _remote.getComments(subjectId,
                limit: limit, offset: offset, cancelToken: cancelToken);
            if (cancelToken?.isCancelled ?? false) {
              throw cancelToken!.cancelError!;
            }
            // 首页获取成功后才清理旧页，失败时仍可回退到完整旧缓存。
            if (offset == 0 && isCurrent()) {
              generation = await invalidateCommentsCache(subjectId);
            }
            return page;
          },
          fromJson: SubjectCommentItem.fromJson,
          toJson: (item) => item.toJson(),
          cancelToken: cancelToken,
          forceRefresh: forceRefresh,
          maxAge: const Duration(hours: 1),
          maxEntries: 20,
          shouldCache: isCurrent,
        );
        if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
        if (isCurrent()) return result;
      } catch (_) {
        if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
        if (isCurrent()) rethrow;
      }
      // 失效期间的响应不能写回或交给页面，仍有效的请求重新加载。
    }
  }

  Future<int> invalidateCommentsCache(int subjectId) {
    final generation = (_commentsGenerations[subjectId] ?? 0) + 1;
    _commentsGenerations[subjectId] = generation;
    _commentsCacheReady = _commentsCacheReady.then((_) async {
      final box = Storage.subjectCommentsCache;
      final keys = box.keys
          .whereType<String>()
          .where((key) => key.startsWith('$subjectId:'))
          .toList();
      await box.deleteAll(keys);
    }).catchError((Object error) {
      debugPrint('Failed to clear comments cache: $error');
    });
    return _commentsCacheReady.then((_) => generation);
  }

  Future<SubjectRelationItem> getRelated(
    int subjectId, {
    required int limit,
    required int offset,
    int? type = 2,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) =>
      JsonResponseCache.get(
        Storage.subjectMetadataCache,
        jsonEncode(['related', subjectId, limit, offset, type]),
        load: () => _remote.getRelated(subjectId,
            limit: limit, offset: offset, type: type, cancelToken: cancelToken),
        fromJson: SubjectRelationItem.fromJson,
        toJson: (item) => item.toJson(),
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

  Future<ProducersItem> getProducers(
    int subjectId, {
    required int limit,
    required int offset,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) =>
      JsonResponseCache.get(
        Storage.subjectMetadataCache,
        jsonEncode(['producers', subjectId, limit, offset]),
        load: () => _remote.getProducers(subjectId,
            limit: limit, offset: offset, cancelToken: cancelToken),
        fromJson: ProducersItem.fromJson,
        toJson: (item) => item.toJson(),
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );
}

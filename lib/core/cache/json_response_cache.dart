import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

class CachedJsonResponse<T> {
  const CachedJsonResponse(this.data, {required this.isFresh});

  final T data;
  final bool isFresh;
}

/// 公开资料的持久化缓存：有效期内复用，过期后刷新，失败时保留旧数据。
class JsonResponseCache {
  static const defaultMaxAge = Duration(hours: 12);
  static final _revisions = Expando<int>();

  /// 清理前发出的请求仍可交给页面，但不能重新写入已清理的缓存。
  static int revisionOf(Box<String> box) => _revisions[box] ?? 0;

  static Future<void> clear(Box<String> box) async {
    _revisions[box] = revisionOf(box) + 1;
    await box.clear();
  }

  /// 读取缓存及其新鲜度，由调用方决定是否先展示旧数据并后台刷新。
  static CachedJsonResponse<T>? read<T>(
    Box<String> box,
    String key, {
    required T Function(Map<String, dynamic>) fromJson,
    Duration maxAge = defaultMaxAge,
  }) {
    try {
      final raw = box.get(key);
      if (raw == null) return null;
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final data = fromJson(entry['data'] as Map<String, dynamic>);
      final age =
          DateTime.now().millisecondsSinceEpoch - (entry['cachedAt'] as int);
      return CachedJsonResponse(data,
          isFresh: age >= 0 && age < maxAge.inMilliseconds);
    } catch (error) {
      debugPrint('Failed to read response cache: $error');
      return null;
    }
  }

  static Future<T> get<T>(
    Box<String> box,
    String key, {
    required Future<T> Function() load,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    CancelToken? cancelToken,
    bool forceRefresh = false,
    bool fallbackToCache = true,
    Duration maxAge = defaultMaxAge,
    int maxEntries = 100,
    // A caller may invalidate a group of pages while a request is in flight.
    bool Function()? shouldCache,
  }) async {
    if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
    final revision = revisionOf(box);
    final cached = read(box, key, fromJson: fromJson, maxAge: maxAge);
    if (!forceRefresh && cached != null && cached.isFresh) {
      return cached.data;
    }

    final T result;
    try {
      result = await load();
    } catch (error) {
      if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
      if (cached == null || !fallbackToCache) rethrow;
      debugPrint('Failed to refresh response cache: $error');
      return cached.data;
    }
    if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
    if (revision != revisionOf(box) ||
        (shouldCache != null && !shouldCache())) {
      return result;
    }
    try {
      await box.put(
          key,
          jsonEncode({
            'cachedAt': DateTime.now().millisecondsSinceEpoch,
            'data': toJson(result),
          }));
      if (box.length > maxEntries) {
        final entries = box.toMap().entries.toList()
          ..sort((a, b) => _cachedAt(a.value).compareTo(_cachedAt(b.value)));
        await box.deleteAll(
          entries.take(box.length - maxEntries).map((entry) => entry.key),
        );
      }
    } catch (error) {
      debugPrint('Failed to write response cache: $error');
    }
    return result;
  }

  static int _cachedAt(String raw) {
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)['cachedAt'] as int;
    } catch (_) {
      return 0;
    }
  }
}

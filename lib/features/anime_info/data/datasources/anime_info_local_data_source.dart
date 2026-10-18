import 'dart:convert';

import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';

/// 将条目序列化为 JSON 存入 Hive，嵌套模型无需注册类型适配器。
class AnimeInfoLocalDataSource {
  static const _maxEntries = 100;

  String _key(int subjectId, String? sessionId) =>
      jsonEncode([sessionId, subjectId]);

  ({SubjectsInfoItem subject, int cachedAt})? read(
    int subjectId, {
    required String? sessionId,
  }) {
    final key = _key(subjectId, sessionId);
    final raw = Storage.animeInfoCache.get(key);
    if (raw == null) return null;
    final entry = jsonDecode(raw) as Map<String, dynamic>;
    final subject = SubjectsInfoItem.fromJson(entry['subject']);
    return subject.id == subjectId
        ? (subject: subject, cachedAt: entry['cachedAt'] as int)
        : null;
  }

  Future<void> write(
    SubjectsInfoItem subject, {
    required String? sessionId,
  }) async {
    final box = Storage.animeInfoCache;
    await box.put(
      _key(subject.id, sessionId),
      jsonEncode({
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'subject': subject.toJson(),
      }),
    );
    if (box.length <= _maxEntries) return;

    // 保留过期缓存以便离线展示，仅在超出容量时按最后成功写入时间淘汰最旧的数据。
    final entries = box
        .toMap()
        .entries
        .map((entry) => (key: entry.key, cachedAt: _cachedAt(entry.value)))
        .toList()
      ..sort((a, b) => a.cachedAt.compareTo(b.cachedAt));
    await box.deleteAll(
      entries.take(box.length - _maxEntries).map((entry) => entry.key),
    );
  }

  int _cachedAt(String raw) {
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)['cachedAt'] as int;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clear() async {
    await Storage.animeInfoCache.clear();
  }
}

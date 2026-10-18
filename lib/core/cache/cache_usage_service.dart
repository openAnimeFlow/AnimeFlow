import 'dart:io';

import 'package:anime_flow/core/cache/json_response_cache.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:hive_ce/hive.dart';

enum CacheCategory {
  images,
  animeInfo,
  characters,
  subjectMetadata,
  subjectComments,
  popularAnime,
  calendar,
}

class CacheUsage {
  CacheUsage(Map<CacheCategory, int> sizes) : sizes = Map.unmodifiable(sizes);

  final Map<CacheCategory, int> sizes;

  int get totalBytes => sizes.values.fold(0, (total, bytes) => total + bytes);
}

class CacheUsageService {
  Map<CacheCategory, Box<String>> get _boxes => {
        CacheCategory.animeInfo: Storage.animeInfoCache,
        CacheCategory.characters: Storage.characterDataCache,
        CacheCategory.subjectMetadata: Storage.subjectMetadataCache,
        CacheCategory.subjectComments: Storage.subjectCommentsCache,
        CacheCategory.popularAnime: Storage.popularAnimeCache,
        CacheCategory.calendar: Storage.calendarCache,
      };

  Future<void> clearData(Set<CacheCategory> selected) async {
    await Future.wait(_boxes.entries
        .where((entry) => selected.contains(entry.key))
        .map((entry) => JsonResponseCache.clear(entry.value)));
  }

  /// 统计缓存文件实际占用，包含 Hive 尚未压缩的旧记录。
  Future<Map<CacheCategory, int>> dataSizesInBytes() async {
    final sizes = await Future.wait(_boxes.entries.map((entry) async {
      final box = entry.value;
      await box.flush();
      final path = box.path;
      final stat = path == null ? null : await File(path).stat();
      final bytes = stat?.type == FileSystemEntityType.file ? stat!.size : 0;
      return MapEntry(entry.key, bytes);
    }));
    return Map.unmodifiable(Map.fromEntries(sizes));
  }
}

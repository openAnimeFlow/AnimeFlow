import 'dart:io';

import 'package:anime_flow/core/network/image/image_cache_manager.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  ImageCacheService({CacheManager? cacheManager})
      : _cacheManager = cacheManager ?? AnimeImageCacheManager.instance;

  final CacheManager _cacheManager;

  Stream<File> _files() async* {
    final temporary = await getTemporaryDirectory();
    final directory =
        Directory(p.join(temporary.path, _cacheManager.config.cacheKey));
    if (!await directory.exists()) return;
    yield* directory
        .list(recursive: true, followLinks: false)
        .where((entry) => entry is File)
        .cast<File>();
  }

  Future<int> sizeInBytes() async {
    var bytes = 0;
    await for (final file in _files()) {
      // Cache files can expire while the directory is being enumerated.
      final stat = await file.stat();
      if (stat.type == FileSystemEntityType.file) bytes += stat.size;
    }
    return bytes;
  }

  Future<void> clear() async {
    // Also remove orphaned files without deleting the entire temporary directory.
    final files = await _files().toList();
    await _cacheManager.emptyCache();
    for (final file in files) {
      try {
        await file.delete();
      } on PathNotFoundException {
        // The cache manager may already have removed this file.
      }
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}

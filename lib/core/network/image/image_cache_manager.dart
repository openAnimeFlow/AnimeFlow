import 'package:anime_flow/core/network/image/image_file_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AnimeImageCacheManager extends CacheManager with ImageCacheManager {
  static final AnimeImageCacheManager instance =
      AnimeImageCacheManager._(ImageFileService());

  AnimeImageCacheManager._(this._fileService)
      : super(Config(DefaultCacheManager.key, fileService: _fileService));

  final ImageFileService _fileService;

  @override
  Future<void> dispose() async {
    _fileService.close();
    await super.dispose();
  }
}

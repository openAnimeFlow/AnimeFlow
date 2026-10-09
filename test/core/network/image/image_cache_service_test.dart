import 'dart:io';

import 'package:anime_flow/core/network/image/image_cache_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  const cacheKey = 'image_cache_service_test';
  late Directory temporary;
  late Directory cacheDirectory;
  late CacheManager manager;
  late ImageCacheService service;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('anime_image_cache_');
    cacheDirectory = Directory(p.join(temporary.path, cacheKey));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async {
      if (call.method == 'getTemporaryDirectory') return temporary.path;
      throw MissingPluginException(call.method);
    });
    manager = CacheManager(Config(
      cacheKey,
      repo: JsonCacheInfoRepository(
        path: p.join(temporary.path, 'cache_metadata.json'),
      ),
    ));
    service = ImageCacheService(cacheManager: manager);
    // Wait for the cache manager's asynchronous file system and database setup.
    await manager.config.fileSystem.createFile('unused');
    await manager.config.repo.open();
  });

  tearDown(() async {
    await manager.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    await temporary.delete(recursive: true);
  });

  test('counts actual image files including nested orphaned files', () async {
    await File(p.join(cacheDirectory.path, 'cover.jpg'))
        .writeAsBytes(Uint8List(1024));
    final nested = Directory(p.join(cacheDirectory.path, 'nested'));
    await nested.create();
    await File(p.join(nested.path, 'orphan.png')).writeAsBytes(Uint8List(2048));
    await File(p.join(temporary.path, 'video.mp4'))
        .writeAsBytes(Uint8List(4096));

    expect(await service.sizeInBytes(), 3072);
  });

  test('returns zero when the image cache directory is missing', () async {
    await cacheDirectory.delete(recursive: true);

    expect(await service.sizeInBytes(), 0);
  });

  test('clears tracked and orphaned images while preserving other data',
      () async {
    const url = 'https://example.test/cover.jpg';
    final tracked = await manager.putFile(url, Uint8List(1024));
    final cached = await manager.getFileFromCache(url);
    // Ensure the fire-and-forget metadata insert has completed before clearing.
    expect(cached, isNotNull);
    final orphan = File(p.join(cacheDirectory.path, 'orphan.png'));
    await orphan.writeAsBytes(Uint8List(512));
    final video = File(p.join(temporary.path, 'video.mp4'));
    await video.writeAsBytes(Uint8List(4096));
    final settings = File(p.join(temporary.path, 'settings.json'));
    await settings.writeAsString('{"language":"zh"}');

    await service.clear();

    expect(await tracked.exists(), isFalse);
    expect(await orphan.exists(), isFalse);
    expect(await manager.getFileFromCache(url), isNull);
    expect(await service.sizeInBytes(), 0);
    expect(await video.length(), 4096);
    expect(await settings.readAsString(), '{"language":"zh"}');
    await service.clear();
    expect(await service.sizeInBytes(), 0);
  });
}

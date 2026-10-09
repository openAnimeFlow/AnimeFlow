import 'dart:io';

import 'package:anime_flow/features/download/application/download_danmaku_service.dart';
import 'package:anime_flow/features/download/application/download_directory/download_directory_platform.dart';
import 'package:anime_flow/features/download/application/download_directory/impl/android_download_directory_platform.dart';
import 'package:anime_flow/features/download/application/download_directory/impl/desktop_download_directory_platform.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('anime_flow/download_storage');
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('download_directory_test_');
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await temp.delete(recursive: true);
  });

  test('preflight creates a new directory and removes the write probe',
      () async {
    final path = p.join(temp.path, 'downloads', 'episode');
    final result = await const DesktopDownloadDirectoryPlatform()
        .requireWritableDirectory(path);
    expect(result, path);
    expect(Directory(path).listSync(), isEmpty);
  });

  test('preflight verifies existing directories without changing their files',
      () async {
    final partial = File(p.join(temp.path, 'video.mp4.tmp'))
      ..writeAsStringSync('cached-data');
    await const DesktopDownloadDirectoryPlatform()
        .requireWritableDirectory(temp.path);
    expect(partial.readAsStringSync(), 'cached-data');
    expect(temp.listSync().map((file) => p.basename(file.path)),
        ['video.mp4.tmp']);
  });

  test('Android rechecks revoked grants without requesting permissions',
      () async {
    var granted = true;
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      expect(call.method, 'hasDirectoryAccess');
      expect((call.arguments as Map)['path'], temp.path);
      return granted;
    });
    const platform = AndroidDownloadDirectoryPlatform();
    await platform.requireWritableDirectory(temp.path);
    granted = false;
    await expectLater(platform.requireWritableDirectory(temp.path),
        throwsA(isA<DownloadDirectoryAccessException>()));
    expect(calls, ['hasDirectoryAccess', 'hasDirectoryAccess']);
    expect(temp.listSync(), isEmpty);
  });

  test('Android checks access before creating a shared-storage folder',
      () async {
    final target = p.join(temp.path, 'denied');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'hasDirectoryAccess');
      return false;
    });
    await expectLater(
        const AndroidDownloadDirectoryPlatform()
            .requireWritableDirectory(target),
        throwsA(isA<DownloadDirectoryAccessException>()));
    expect(Directory(target).existsSync(), isFalse);
  });

  test('danmaku preflight rejects bad storage before calling the API',
      () async {
    final file = File(p.join(temp.path, 'not-directory'))
      ..writeAsStringSync('keep');
    final episode = DownloadEpisode(
      episodeUrl: 'episode',
      bangumiEpisodeId: 1,
      episodeSort: 1,
      episodeIndex: 1,
      episodeTitle: 'Episode',
      lineIndex: 0,
      sourceName: 'source',
      status: DownloadStatus.completed,
      downloadDirectory: file.path,
      localMediaPath: 'existing-video.mp4',
    );
    final service = DownloadDanmakuService(
      directoryPlatform: const DesktopDownloadDirectoryPlatform(),
    );
    await expectLater(service.download(subjectId: 1, episode: episode),
        throwsA(isA<DownloadDirectoryNotWritableException>()));
    expect(episode.status, DownloadStatus.completed);
    expect(episode.localMediaPath, 'existing-video.mp4');
    expect(file.readAsStringSync(), 'keep');
  });
}

import 'dart:io';

import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/download/application/download_directory/restore_download_directory_access.dart';
import 'package:anime_flow/features/download/application/download_manager.dart';
import 'package:anime_flow/hive_registrar.g.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('anime_flow/download_directory');
  late Directory temp;
  var roots = <String, String>{};
  var restoreFails = false;
  var restoreCalls = 0;

  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('download_bookmarks_test_');
    Hive.init(temp.path);
    Hive.registerAdapters();
    Storage.setting = await Hive.openBox<dynamic>('settings');
    Storage.downloads = await Hive.openBox<DownloadRecord>('downloads');
  });

  setUp(() async {
    await Storage.setting.clear();
    await Storage.downloads.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    roots = {};
    restoreFails = false;
    restoreCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'restoreBookmarks');
      restoreCalls++;
      if (restoreFails) throw PlatformException(code: 'restore_failed');
      return roots;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  tearDownAll(() async {
    await Hive.close();
    await temp.delete(recursive: true);
  });

  test('startup restores grants before completed video and danmaku are read',
      () async {
    final oldRoot = p.join(temp.path, 'before-move');
    final newRoot = p.join(temp.path, 'after-move');
    final directory = p.join(oldRoot, 'source_1', '1');
    final episode = _episode(directory);
    final record = _record(1, episode);
    await Storage.downloads.put(record.key, record);
    await AppSettings.setDownloadDirectory(oldRoot);
    roots = {oldRoot: newRoot};
    final newDirectory = Directory(p.join(newRoot, 'source_1', '1'));
    await newDirectory.create(recursive: true);
    await File(p.join(newDirectory.path, 'video.mp4')).writeAsString('video');
    await File(p.join(newDirectory.path, 'danmaku.json')).writeAsString('{}');

    await restoreDownloadDirectoryAccess();

    expect(restoreCalls, 1);
    expect(AppSettings.downloadDirectory, newRoot);
    final restored = Storage.downloads.get(record.key)!.episodes['episode']!;
    expect(restored.downloadDirectory, newDirectory.path);
    expect(
        restored.localDanmakuPath, p.join(newDirectory.path, 'danmaku.json'));
    final manager = DownloadManager();
    expect(manager.getLocalMediaPath(restored),
        p.join(newDirectory.path, 'video.mp4'));
  });

  test('startup preserves older roots and records with failed grants',
      () async {
    final olderRoot = p.join(temp.path, 'older');
    final failedRoot = p.join(temp.path, 'failed');
    final older = _record(1, _episode(p.join(olderRoot, 'source_1', '1')));
    final failed = _record(2, _episode(p.join(failedRoot, 'source_2', '1')));
    await Storage.downloads.put(older.key, older);
    await Storage.downloads.put(failed.key, failed);
    await AppSettings.setDownloadDirectory(failedRoot);
    roots = {olderRoot: olderRoot};

    await restoreDownloadDirectoryAccess();

    expect(restoreCalls, 1);
    expect(AppSettings.downloadDirectory, failedRoot);
    expect(
        Storage.downloads
            .get(older.key)!
            .episodes['episode']!
            .downloadDirectory,
        p.join(olderRoot, 'source_1', '1'));
    expect(
        Storage.downloads
            .get(failed.key)!
            .episodes['episode']!
            .downloadDirectory,
        p.join(failedRoot, 'source_2', '1'));
  });

  test('failed restoration does not prevent startup or erase settings',
      () async {
    final directory = p.join(temp.path, 'unavailable');
    await AppSettings.setDownloadDirectory(directory);
    restoreFails = true;
    await restoreDownloadDirectoryAccess();
    expect(AppSettings.downloadDirectory, directory);
  });

  test('other platforms do not invoke the macOS channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await restoreDownloadDirectoryAccess();
    expect(restoreCalls, 0);
  });

  test('path mapping uses the deepest grant and preserves unrelated paths', () {
    final root = p.join(temp.path, 'root');
    final nested = p.join(root, 'nested');
    final moved = p.join(temp.path, 'moved');
    final movedNested = p.join(temp.path, 'moved-nested');
    final mappings = {root: moved, nested: movedNested};
    expect(remapDownloadPath(root, mappings), moved);
    expect(remapDownloadPath(p.join(nested, 'video.mp4'), mappings),
        p.join(movedNested, 'video.mp4'));
    final unrelated = p.join('$root-sibling', 'video.mp4');
    expect(remapDownloadPath(unrelated, mappings), unrelated);
    expect(remapDownloadPath('', mappings), '');
  });
}

DownloadEpisode _episode(String directory) => DownloadEpisode(
      episodeUrl: 'episode',
      bangumiEpisodeId: 1,
      episodeSort: 1,
      episodeIndex: 1,
      episodeTitle: 'Episode 1',
      lineIndex: 0,
      sourceName: 'source',
      status: DownloadStatus.completed,
      downloadDirectory: directory,
      localMediaPath: p.join(directory, 'video.mp4'),
      localDanmakuPath: p.join(directory, 'danmaku.json'),
    );

DownloadRecord _record(int subjectId, DownloadEpisode episode) =>
    DownloadRecord(
      subjectId: subjectId,
      subjectName: 'Subject',
      subjectCover: '',
      sourceName: 'source',
      sourceBaseUrl: 'https://example.com',
      episodes: {'episode': episode},
      createdAt: DateTime(2026),
    );

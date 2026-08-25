import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/features/download/application/download_http_client.dart';
import 'package:anime_flow/features/download/application/download_manager.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late HttpServer server;
  late Uri baseUri;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync(
      'anime_flow_download_manager_test_',
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUri = Uri.parse('http://${server.address.host}:${server.port}');
    _serveRequests(server);
  });

  tearDown(() async {
    await server.close(force: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DownloadManager', () {
    test('downloads direct media to video file', () async {
      final episode = _episode(url: 'direct');
      final manager = _manager(tempDir);

      final completed = _waitForCompletion(manager);
      await manager.enqueue(
        _request(
          episode: episode,
          baseUri: baseUri,
          networkMediaUrl: baseUri.resolve('/direct.mp4').toString(),
        ),
      );

      final result = await completed;

      expect(result.status, DownloadStatus.completed);
      expect(result.mediaType, 'direct');
      expect(result.progressPercent, 1);
      expect(result.localMediaPath.endsWith('video.mp4'), isTrue);
      expect(File(result.localMediaPath).readAsStringSync(), 'direct-body');
    });

    test('downloads direct media without playlist probing', () async {
      final episode = _episode(url: 'direct-no-probe');
      final manager = _manager(tempDir);

      final completed = _waitForCompletion(manager);
      await manager.enqueue(
        _request(
          episode: episode,
          episodeUrl: 'direct-no-probe',
          baseUri: baseUri,
          networkMediaUrl: baseUri.resolve('/direct-no-probe.mp4').toString(),
        ),
      );

      final result = await completed;

      expect(result.status, DownloadStatus.completed);
      expect(File(result.localMediaPath).readAsStringSync(), 'no-probe-body');
    });

    test('retries direct media without referer after client error', () async {
      final episode = _episode(url: 'direct-referer-retry');
      final manager = _manager(tempDir);

      final completed = _waitForCompletion(manager);
      await manager.enqueue(
        _request(
          episode: episode,
          episodeUrl: 'direct-referer-retry',
          baseUri: baseUri,
          networkMediaUrl:
              baseUri.resolve('/direct-referer-retry.mp4').toString(),
        ),
      );

      final result = await completed;

      expect(result.status, DownloadStatus.completed);
      expect(File(result.localMediaPath).readAsStringSync(), 'retry-body');
    });

    test('resumes direct media from existing tmp file with Range header',
        () async {
      final episode = _episode(url: 'range');
      final episodeDir = p.join(tempDir.path, 'source_1', '1');
      await Directory(episodeDir).create(recursive: true);
      await File(p.join(episodeDir, 'video.mp4.tmp')).writeAsString('direct-');
      episode.downloadDirectory = episodeDir;
      final manager = _manager(tempDir);

      final completed = _waitForCompletion(manager);
      await manager.enqueue(
        _request(
          episode: episode,
          episodeUrl: 'range',
          baseUri: baseUri,
          networkMediaUrl: baseUri.resolve('/range.mp4').toString(),
        ),
      );

      final result = await completed;

      expect(result.status, DownloadStatus.completed);
      expect(File(result.localMediaPath).readAsStringSync(), 'direct-body');
    });

    test('downloads m3u8 playlist segments and builds local playlist',
        () async {
      final episode = _episode(url: 'm3u8');
      final manager = _manager(tempDir);

      final completed = _waitForCompletion(manager);
      await manager.enqueue(
        _request(
          episode: episode,
          episodeUrl: 'm3u8',
          baseUri: baseUri,
          networkMediaUrl: baseUri.resolve('/playlist.m3u8').toString(),
        ),
      );

      final result = await completed;
      final episodeDir = Directory(result.downloadDirectory);

      expect(result.status, DownloadStatus.completed);
      expect(result.mediaType, 'm3u8');
      expect(result.downloadedSegments, 2);
      expect(File(p.join(episodeDir.path, 'seg_00000.ts')).readAsStringSync(),
          'segment-0');
      expect(File(p.join(episodeDir.path, 'seg_00001.ts')).readAsStringSync(),
          'segment-1');
      expect(File(p.join(episodeDir.path, 'key_0.key')).readAsStringSync(),
          'secret-key');

      final playlist = File(result.localMediaPath).readAsStringSync();
      expect(playlist, contains('seg_00000.ts'));
      expect(playlist, contains('seg_00001.ts'));
      expect(playlist, contains('URI="key_0.key"'));
    });

    test('deletes episode download directory', () async {
      final episodeDir = p.join(tempDir.path, 'source_1', 'delete-me');
      await Directory(episodeDir).create(recursive: true);
      await File(p.join(episodeDir, 'video.mp4')).writeAsString('body');
      final episode = _episode(url: 'delete')..downloadDirectory = episodeDir;
      final manager = _manager(tempDir);

      await manager.deleteEpisodeFiles(episode);

      expect(Directory(episodeDir).existsSync(), isFalse);
    });
  });
}

DownloadManager _manager(Directory tempDir) {
  return DownloadManager(
    httpClient: DownloadHttpClient(dio: Dio()),
    baseDirectoryProvider: () async => tempDir.path,
    maxParallelEpisodes: 1,
    maxParallelSegments: 2,
  );
}

DownloadRequest _request({
  required DownloadEpisode episode,
  required Uri baseUri,
  required String networkMediaUrl,
  String episodeUrl = 'direct',
}) {
  return DownloadRequest(
    recordKey: 'source_1',
    subjectId: 1,
    sourceName: 'source',
    episodeUrl: episodeUrl,
    networkMediaUrl: networkMediaUrl,
    httpHeaders: {'referer': baseUri.toString()},
    episode: episode,
  );
}

DownloadEpisode _episode({required String url}) {
  return DownloadEpisode(
    episodeUrl: url,
    bangumiEpisodeId: 10,
    episodeSort: 1,
    episodeIndex: 1,
    episodeTitle: 'Episode 1',
    lineIndex: 0,
    sourceName: 'source',
    status: DownloadStatus.pending,
  );
}

Future<DownloadEpisode> _waitForCompletion(DownloadManager manager) {
  final completer = Completer<DownloadEpisode>();
  manager.onProgress = (recordKey, episodeUrl, episode, speed) {
    if (completer.isCompleted) {
      return;
    }
    if (episode.status == DownloadStatus.completed) {
      completer.complete(episode);
    } else if (episode.status == DownloadStatus.failed) {
      completer.completeError(episode.errorMessage);
    }
  };
  return completer.future.timeout(const Duration(seconds: 10));
}

void _serveRequests(HttpServer server) {
  server.listen((request) async {
    switch (request.uri.path) {
      case '/direct.mp4':
        request.response.write('direct-body');
      case '/direct-no-probe.mp4':
        if (request.headers.value(HttpHeaders.acceptHeader) != '*/*') {
          request.response.statusCode = HttpStatus.badRequest;
        } else {
          request.response.write('no-probe-body');
        }
      case '/direct-referer-retry.mp4':
        if (request.headers.value(HttpHeaders.refererHeader) != null) {
          request.response.statusCode = HttpStatus.badRequest;
        } else {
          request.response.write('retry-body');
        }
      case '/range.mp4':
        final full = utf8.encode('direct-body');
        final range = request.headers.value(HttpHeaders.rangeHeader);
        if (range == 'bytes=7-') {
          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes 7-10/11',
          );
          request.response.add(full.sublist(7));
        } else {
          request.response.add(full);
        }
      case '/playlist.m3u8':
        request.response.write('''
#EXTM3U
#EXT-X-TARGETDURATION:5
#EXT-X-PLAYLIST-TYPE:VOD
#EXT-X-KEY:METHOD=AES-128,URI="key.key"
#EXTINF:5,
seg0.ts
#EXTINF:5,
seg1.ts
#EXT-X-ENDLIST
''');
      case '/key.key':
        request.response.write('secret-key');
      case '/seg0.ts':
        request.response.write('segment-0');
      case '/seg1.ts':
        request.response.write('segment-1');
      default:
        request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  });
}

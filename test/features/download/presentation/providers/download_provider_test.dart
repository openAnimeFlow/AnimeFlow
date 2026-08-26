import 'dart:async';

import 'package:anime_flow/features/download/application/download_danmaku_service.dart';
import 'package:anime_flow/features/download/application/download_manager.dart';
import 'package:anime_flow/features/download/application/video_source_resolver_pool.dart';
import 'package:anime_flow/features/download/data/repositories/download_repository.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_service.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DownloadController', () {
    test('creates record and enqueues pre-resolved download', () async {
      final repository = _FakeDownloadRepository();
      final manager = _FakeDownloadManager();
      final resolverPool = _FakeResolverPool();
      final container = ProviderContainer(
        overrides: [
          downloadRepositoryProvider.overrideWithValue(repository),
          downloadManagerProvider.overrideWithValue(manager),
          videoSourceResolverPoolProvider.overrideWithValue(resolverPool),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(downloadControllerProvider.notifier)
          .startDownload(_params(networkMediaUrl: 'https://cdn.test/ep1.m3u8'));

      final state = container.read(downloadControllerProvider);
      expect(state.totalTasks, 1);
      expect(repository.records.single.subjectName, 'Subject');
      expect(
          manager.requests.single.networkMediaUrl, 'https://cdn.test/ep1.m3u8');
      expect(resolverPool.resolveCount, 0);
      expect(
        repository.records.single.episodes.values.single.status,
        DownloadStatus.downloading,
      );
    });

    test('resolves media url before enqueue when networkMediaUrl is empty',
        () async {
      final repository = _FakeDownloadRepository();
      final manager = _FakeDownloadManager();
      final resolverPool = _FakeResolverPool(
        resolvedUrl: 'https://cdn.test/resolved.m3u8',
      );
      final container = ProviderContainer(
        overrides: [
          downloadRepositoryProvider.overrideWithValue(repository),
          downloadManagerProvider.overrideWithValue(manager),
          videoSourceResolverPoolProvider.overrideWithValue(resolverPool),
        ],
      );
      addTearDown(container.dispose);

      await container.read(downloadControllerProvider.notifier).startDownload(
            _params(networkMediaUrl: ''),
          );

      expect(resolverPool.resolveCount, 1);
      expect(manager.requests.single.networkMediaUrl,
          'https://cdn.test/resolved.m3u8');
    });

    test('resets incomplete downloads to paused on build', () async {
      final repository = _FakeDownloadRepository();
      final manager = _FakeDownloadManager();
      final resolverPool = _FakeResolverPool();
      final record = DownloadRecord(
        subjectId: 1,
        subjectName: 'Subject',
        subjectCover: '',
        sourceName: 'source',
        sourceBaseUrl: 'https://source.test',
        episodes: {
          'downloading': _episode('downloading', DownloadStatus.downloading),
          'pending': _episode('pending', DownloadStatus.pending),
          'resolving': _episode('resolving', DownloadStatus.resolving),
          'completed': _episode('completed', DownloadStatus.completed),
        },
        createdAt: DateTime(2026),
      );
      await repository.putRecord(record);
      final container = ProviderContainer(
        overrides: [
          downloadRepositoryProvider.overrideWithValue(repository),
          downloadManagerProvider.overrideWithValue(manager),
          videoSourceResolverPoolProvider.overrideWithValue(resolverPool),
        ],
      );
      addTearDown(container.dispose);

      container.read(downloadControllerProvider);
      await Future<void>.delayed(Duration.zero);

      final episodes = repository.records.single.episodes;
      expect(episodes['downloading']?.status, DownloadStatus.paused);
      expect(episodes['pending']?.status, DownloadStatus.paused);
      expect(episodes['resolving']?.status, DownloadStatus.paused);
      expect(episodes['completed']?.status, DownloadStatus.completed);
    });

    test('delete episode cancels task, deletes files, and removes record entry',
        () async {
      final repository = _FakeDownloadRepository();
      final manager = _FakeDownloadManager();
      final resolverPool = _FakeResolverPool();
      final record = DownloadRecord(
        subjectId: 1,
        subjectName: 'Subject',
        subjectCover: '',
        sourceName: 'source',
        sourceBaseUrl: 'https://source.test',
        episodes: {
          'ep1': _episode('ep1', DownloadStatus.completed),
        },
        createdAt: DateTime(2026),
      );
      await repository.putRecord(record);
      final container = ProviderContainer(
        overrides: [
          downloadRepositoryProvider.overrideWithValue(repository),
          downloadManagerProvider.overrideWithValue(manager),
          videoSourceResolverPoolProvider.overrideWithValue(resolverPool),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(downloadControllerProvider.notifier)
          .deleteEpisode(record.key, 'ep1');

      expect(manager.cancelled, [(record.key, 'ep1')]);
      expect(manager.deletedEpisodes.single.episodeUrl, 'ep1');
      expect(repository.getRecord(record.key), isNull);
    });

    test('pause immediately persists paused status and refreshes state',
        () async {
      final repository = _FakeDownloadRepository();
      final manager = _FakeDownloadManager();
      final resolverPool = _FakeResolverPool();
      final record = DownloadRecord(
        subjectId: 1,
        subjectName: 'Subject',
        subjectCover: '',
        sourceName: 'source',
        sourceBaseUrl: 'https://source.test',
        episodes: {
          'ep1': _episode('ep1', DownloadStatus.downloading),
        },
        createdAt: DateTime(2026),
      );
      await repository.putRecord(record);
      final container = ProviderContainer(
        overrides: [
          downloadRepositoryProvider.overrideWithValue(repository),
          downloadManagerProvider.overrideWithValue(manager),
          videoSourceResolverPoolProvider.overrideWithValue(resolverPool),
        ],
      );
      addTearDown(container.dispose);

      await container.read(downloadControllerProvider.notifier).pause(
            record.key,
            'ep1',
          );

      expect(manager.paused, [(record.key, 'ep1')]);
      expect(
        repository.getRecord(record.key)?.episodes['ep1']?.status,
        DownloadStatus.paused,
      );
      expect(
        container
            .read(downloadControllerProvider)
            .records
            .single
            .episodes['ep1']
            ?.status,
        DownloadStatus.paused,
      );
    });

    test('downloads danmaku after video completes when enabled', () async {
      final repository = _FakeDownloadRepository();
      final manager = _FakeDownloadManager();
      final resolverPool = _FakeResolverPool();
      final danmakuService = _FakeDownloadDanmakuService(
        result: const DownloadDanmakuResult(
          danDanBangumiId: 2026,
          localPath: 'downloads/ep1/danmaku.json',
          hasDanmaku: true,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          downloadRepositoryProvider.overrideWithValue(repository),
          downloadManagerProvider.overrideWithValue(manager),
          videoSourceResolverPoolProvider.overrideWithValue(resolverPool),
          downloadDanmakuServiceProvider.overrideWithValue(danmakuService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(downloadControllerProvider.notifier).startDownload(
            _params(
              networkMediaUrl: 'https://cdn.test/ep1.m3u8',
              downloadDanmaku: true,
            ),
          );

      final request = manager.requests.single;
      request.episode
        ..status = DownloadStatus.completed
        ..downloadDirectory = 'downloads/ep1';
      manager.onProgress?.call(
        request.recordKey,
        request.episodeUrl,
        request.episode,
        0,
      );
      await danmakuService.waitForDownload();
      await Future<void>.delayed(Duration.zero);

      final episode = repository
          .getRecord(request.recordKey)!
          .episodes[request.episodeUrl]!;
      expect(danmakuService.requestedSubjectIds, [1]);
      expect(episode.danDanBangumiID, 2026);
      expect(episode.danmakuDownloaded, isTrue);
      expect(episode.localDanmakuPath, 'downloads/ep1/danmaku.json');
    });

    test('skips danmaku download when disabled for the task', () async {
      final repository = _FakeDownloadRepository();
      final manager = _FakeDownloadManager();
      final resolverPool = _FakeResolverPool();
      final danmakuService = _FakeDownloadDanmakuService(
        result: const DownloadDanmakuResult(
          danDanBangumiId: 2026,
          localPath: 'downloads/ep1/danmaku.json',
          hasDanmaku: true,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          downloadRepositoryProvider.overrideWithValue(repository),
          downloadManagerProvider.overrideWithValue(manager),
          videoSourceResolverPoolProvider.overrideWithValue(resolverPool),
          downloadDanmakuServiceProvider.overrideWithValue(danmakuService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(downloadControllerProvider.notifier).startDownload(
            _params(
              networkMediaUrl: 'https://cdn.test/ep1.m3u8',
              downloadDanmaku: false,
            ),
          );

      final request = manager.requests.single;
      request.episode
        ..status = DownloadStatus.completed
        ..downloadDirectory = 'downloads/ep1';
      manager.onProgress?.call(
        request.recordKey,
        request.episodeUrl,
        request.episode,
        0,
      );
      await Future<void>.delayed(Duration.zero);

      final episode = repository
          .getRecord(request.recordKey)!
          .episodes[request.episodeUrl]!;
      expect(danmakuService.requestedSubjectIds, isEmpty);
      expect(episode.danmakuDownloaded, isFalse);
      expect(episode.localDanmakuPath, isEmpty);
    });

    test(
        'downloads danmaku for a completed episode without redownloading video',
        () async {
      final repository = _FakeDownloadRepository();
      final manager = _FakeDownloadManager();
      final resolverPool = _FakeResolverPool();
      final danmakuService = _FakeDownloadDanmakuService(
        result: const DownloadDanmakuResult(
          danDanBangumiId: 2026,
          localPath: 'downloads/ep1/danmaku.json',
          hasDanmaku: true,
        ),
      );
      final record = DownloadRecord(
        subjectId: 1,
        subjectName: 'Subject',
        subjectCover: '',
        sourceName: 'source',
        sourceBaseUrl: 'https://source.test',
        episodes: {
          'ep1': _episode('ep1', DownloadStatus.completed)
            ..downloadDirectory = 'downloads/ep1',
        },
        createdAt: DateTime(2026),
      );
      await repository.putRecord(record);
      final container = ProviderContainer(
        overrides: [
          downloadRepositoryProvider.overrideWithValue(repository),
          downloadManagerProvider.overrideWithValue(manager),
          videoSourceResolverPoolProvider.overrideWithValue(resolverPool),
          downloadDanmakuServiceProvider.overrideWithValue(danmakuService),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(downloadControllerProvider.notifier)
          .downloadDanmaku(record.key, 'ep1');
      await danmakuService.waitForDownload();

      final episode = repository.getRecord(record.key)!.episodes['ep1']!;
      expect(manager.requests, isEmpty);
      expect(danmakuService.requestedSubjectIds, [1]);
      expect(episode.danmakuDownloaded, isTrue);
      expect(episode.localDanmakuPath, 'downloads/ep1/danmaku.json');
    });
  });
}

StartDownloadParams _params({
  required String networkMediaUrl,
  bool downloadDanmaku = false,
}) {
  return StartDownloadParams(
    subjectId: 1,
    subjectName: 'Subject',
    subjectCover: 'cover',
    sourceName: 'source',
    sourceBaseUrl: 'https://source.test/base/',
    lineIndex: 0,
    episodeUrl: 'ep1',
    episodeTitle: 'Episode 1',
    bangumiEpisodeId: 101,
    episodeSort: 1,
    episodeIndex: 1,
    networkMediaUrl: networkMediaUrl,
    downloadDanmaku: downloadDanmaku,
  );
}

DownloadEpisode _episode(String url, int status) {
  return DownloadEpisode(
    episodeUrl: url,
    bangumiEpisodeId: 1,
    episodeSort: 1,
    episodeIndex: 1,
    episodeTitle: 'Episode 1',
    lineIndex: 0,
    sourceName: 'source',
    status: status,
  );
}

class _FakeDownloadRepository implements IDownloadRepository {
  final recordsByKey = <String, DownloadRecord>{};

  List<DownloadRecord> get records => recordsByKey.values.toList();

  @override
  List<DownloadRecord> getAllRecords() => records;

  @override
  DownloadRecord? getRecord(String key) => recordsByKey[key];

  @override
  Future<void> putRecord(DownloadRecord record) async {
    recordsByKey[record.key] = record;
  }

  @override
  Future<void> updateEpisode(
    String recordKey,
    String episodeUrl,
    DownloadEpisode episode,
  ) async {
    final record = recordsByKey[recordKey];
    if (record == null) {
      return;
    }
    record.episodes = Map<String, DownloadEpisode>.from(record.episodes)
      ..[episodeUrl] = episode;
  }

  @override
  Future<void> deleteEpisode(String recordKey, String episodeUrl) async {
    final record = recordsByKey[recordKey];
    if (record == null) {
      return;
    }
    record.episodes.remove(episodeUrl);
    if (record.episodes.isEmpty) {
      recordsByKey.remove(recordKey);
    }
  }

  @override
  List<DownloadEpisode> getCompletedEpisodes(
    int subjectId,
    String sourceName,
  ) {
    return records
        .expand((record) => record.episodes.values)
        .where((episode) => episode.status == DownloadStatus.completed)
        .toList();
  }

  @override
  DownloadEpisode? getEpisode(
    int subjectId,
    String sourceName,
    String episodeUrl,
  ) {
    return recordsByKey[DownloadRecord.buildKey(
      sourceName: sourceName,
      subjectId: subjectId,
    )]
        ?.episodes[episodeUrl];
  }
}

class _FakeDownloadManager implements IDownloadManager {
  final requests = <DownloadRequest>[];
  final cancelled = <(String, String)>[];
  final paused = <(String, String)>[];
  final deletedEpisodes = <DownloadEpisode>[];

  @override
  int maxParallelEpisodes = 2;

  @override
  int maxParallelSegments = 3;

  @override
  DownloadProgressCallback? onProgress;

  @override
  Future<void> cancel(String recordKey, String episodeUrl) async {
    cancelled.add((recordKey, episodeUrl));
  }

  @override
  Future<void> deleteEpisodeFiles(DownloadEpisode? episode) async {
    if (episode != null) {
      deletedEpisodes.add(episode);
    }
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    requests.add(request);
    request.episode.status = DownloadStatus.downloading;
    onProgress?.call(request.recordKey, request.episodeUrl, request.episode, 0);
  }

  @override
  Future<void> enqueuePriority(DownloadRequest request) async {
    return enqueue(request);
  }

  @override
  double getSpeed(String recordKey, String episodeUrl) => 0;

  @override
  String? getLocalMediaPath(DownloadEpisode? episode) =>
      episode?.localMediaPath;

  @override
  bool isDownloading(String recordKey, String episodeUrl) => false;

  @override
  void pause(String recordKey, String episodeUrl) {
    paused.add((recordKey, episodeUrl));
  }

  @override
  Future<void> resume(DownloadRequest request) async {
    return enqueue(request);
  }
}

class _FakeDownloadDanmakuService implements IDownloadDanmakuService {
  _FakeDownloadDanmakuService({required this.result});

  final DownloadDanmakuResult? result;
  final requestedSubjectIds = <int>[];
  final _downloads = <Completer<void>>[];

  @override
  Future<DownloadDanmakuResult?> download({
    required int subjectId,
    required DownloadEpisode episode,
  }) async {
    requestedSubjectIds.add(subjectId);
    final completer = Completer<void>();
    _downloads.add(completer);
    completer.complete();
    return result;
  }

  Future<void> waitForDownload() async {
    while (_downloads.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    await _downloads.last.future;
  }
}

class _FakeResolverPool implements IVideoSourceResolverPool {
  _FakeResolverPool({this.resolvedUrl = 'https://cdn.test/ep1.m3u8'});

  final String resolvedUrl;
  var resolveCount = 0;

  @override
  void cancelAll() {}

  @override
  void dispose() {}

  @override
  Future<VideoSource> resolve(VideoSourceResolveRequest request) async {
    resolveCount++;
    return VideoSource(
      url: resolvedUrl,
      offset: 0,
      type: VideoSourceType.online,
    );
  }
}

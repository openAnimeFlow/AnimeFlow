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
  });
}

StartDownloadParams _params({required String networkMediaUrl}) {
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
    recordsByKey[recordKey]?.episodes.remove(episodeUrl);
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

  @override
  DownloadProgressCallback? onProgress;

  @override
  void cancel(String recordKey, String episodeUrl) {}

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
  void pause(String recordKey, String episodeUrl) {}

  @override
  Future<void> resume(DownloadRequest request) async {
    return enqueue(request);
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

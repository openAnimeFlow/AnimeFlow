import 'dart:async';

import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/crawler/cookie_manager.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/features/download/application/download_danmaku_service.dart';
import 'package:anime_flow/features/download/application/download_manager.dart';
import 'package:anime_flow/features/download/application/video_source_resolver_pool.dart';
import 'package:anime_flow/features/download/data/repositories/download_repository.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_service.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'download_provider.g.dart';

class DownloadState {
  const DownloadState({
    this.records = const [],
    this.currentSpeed = 0,
    this.totalTasks = 0,
    this.completedTasks = 0,
  });

  final List<DownloadRecord> records;
  final double currentSpeed;
  final int totalTasks;
  final int completedTasks;

  DownloadState copyWith({
    List<DownloadRecord>? records,
    double? currentSpeed,
    int? totalTasks,
    int? completedTasks,
  }) {
    return DownloadState(
      records: records ?? this.records,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }
}

class StartDownloadParams {
  const StartDownloadParams({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCover,
    required this.sourceName,
    required this.sourceBaseUrl,
    required this.lineIndex,
    required this.episodeUrl,
    required this.episodeTitle,
    required this.bangumiEpisodeId,
    required this.episodeSort,
    required this.episodeIndex,
    this.useLegacyParser = false,
    this.networkMediaUrl = '',
    this.downloadDanmaku,
  });

  final int subjectId;
  final String subjectName;
  final String subjectCover;
  final String sourceName;
  final String sourceBaseUrl;
  final int lineIndex;
  final String episodeUrl;
  final String episodeTitle;
  final int bangumiEpisodeId;
  final double episodeSort;
  final int episodeIndex;
  final bool useLegacyParser;

  /// Optional pre-resolved M3U8/MP4 URL. When empty, the controller resolves
  /// [episodeUrl] with an independent WebView resolver from the pool.
  final String networkMediaUrl;
  final bool? downloadDanmaku;

  String get recordKey => DownloadRecord.buildKey(
        sourceName: sourceName,
        subjectId: subjectId,
      );
}

@Riverpod(keepAlive: true)
IDownloadRepository downloadRepository(Ref ref) {
  return DownloadRepository();
}

@Riverpod(keepAlive: true)
IDownloadManager downloadManager(Ref ref) {
  return DownloadManager(
    repository: ref.watch(downloadRepositoryProvider),
    baseDirectoryProvider: _configuredDownloadDirectory,
    maxParallelEpisodes: _downloadSettingInt(
      DownloadKey.maxParallelEpisodes,
      fallback: 2,
    ),
    maxParallelSegments: _downloadSettingInt(
      DownloadKey.maxParallelSegments,
      fallback: 3,
    ),
  );
}

Future<String> _configuredDownloadDirectory() async {
  try {
    final configured = Storage.setting.get(
      DownloadKey.downloadDirectory,
      defaultValue: '',
    );
    if (configured is String && configured.trim().isNotEmpty) {
      return configured.trim();
    }
  } catch (_) {
    // Fall back to the application support directory during startup.
  }
  return DownloadManager.getDefaultDownloadDirectory();
}

int _downloadSettingInt(String key, {required int fallback}) {
  try {
    final value = Storage.setting.get(key, defaultValue: fallback);
    if (value is int) {
      return value.clamp(1, 10).toInt();
    }
  } catch (_) {
    // Use the defaults when storage is unavailable during startup.
  }
  return fallback;
}

@Riverpod(keepAlive: true)
IDownloadDanmakuService downloadDanmakuService(Ref ref) {
  return DownloadDanmakuService();
}

@Riverpod(keepAlive: true)
IVideoSourceResolverPool videoSourceResolverPool(Ref ref) {
  final pool = VideoSourceResolverPool();
  ref.onDispose(pool.dispose);
  return pool;
}

@Riverpod(keepAlive: true)
class DownloadController extends _$DownloadController {
  final _downloadDanmakuByTask = <String, bool>{};
  final _runningDanmakuTasks = <String>{};

  @override
  DownloadState build() {
    final manager = ref.watch(downloadManagerProvider);
    final resolverPool = ref.watch(videoSourceResolverPoolProvider);
    manager.onProgress = (recordKey, episodeUrl, episode, speed) {
      if (episode.status == DownloadStatus.completed) {
        unawaited(_downloadDanmakuIfNeeded(recordKey, episodeUrl, episode));
      }
      _refresh(speed: speed);
    };
    ref.onDispose(() {
      manager.onProgress = null;
      resolverPool.cancelAll();
    });
    unawaited(_resetIncompleteDownloads());
    return _buildState(
      ref.watch(downloadRepositoryProvider).getAllRecords(),
      speed: 0,
    );
  }

  Future<void> startDownload(StartDownloadParams params) async {
    final repository = ref.read(downloadRepositoryProvider);
    final record = repository.getRecord(params.recordKey) ??
        DownloadRecord(
          subjectId: params.subjectId,
          subjectName: params.subjectName,
          subjectCover: params.subjectCover,
          sourceName: params.sourceName,
          sourceBaseUrl: params.sourceBaseUrl,
          episodes: {},
          createdAt: DateTime.now(),
        );

    final normalizedEpisodeUrl = _resolveEpisodeUrl(
      params.sourceBaseUrl,
      params.episodeUrl,
    );
    final taskKey = _taskKey(params.recordKey, normalizedEpisodeUrl);
    _downloadDanmakuByTask[taskKey] =
        params.downloadDanmaku ?? _downloadDanmakuEnabled;
    final existing = record.episodes[normalizedEpisodeUrl];
    final episode = existing ??
        DownloadEpisode(
          episodeUrl: normalizedEpisodeUrl,
          bangumiEpisodeId: params.bangumiEpisodeId,
          episodeSort: params.episodeSort,
          episodeIndex: params.episodeIndex,
          episodeTitle: params.episodeTitle,
          lineIndex: params.lineIndex,
          sourceName: params.sourceName,
          status: DownloadStatus.resolving,
        );

    episode
      ..status = DownloadStatus.resolving
      ..errorMessage = '';
    record.episodes = Map<String, DownloadEpisode>.from(record.episodes)
      ..[normalizedEpisodeUrl] = episode;
    await repository.putRecord(record);
    _refresh();

    try {
      final mediaUrl = params.networkMediaUrl.trim().isNotEmpty
          ? params.networkMediaUrl.trim()
          : await _resolveNetworkMediaUrl(
              normalizedEpisodeUrl,
              useLegacyParser: params.useLegacyParser,
            );
      if (_isEpisodePaused(params.recordKey, normalizedEpisodeUrl)) {
        _refresh(speed: 0);
        return;
      }

      episode.networkMediaUrl = mediaUrl;
      await repository.updateEpisode(
        params.recordKey,
        normalizedEpisodeUrl,
        episode,
      );
      if (_isEpisodePaused(params.recordKey, normalizedEpisodeUrl)) {
        _refresh(speed: 0);
        return;
      }

      await ref.read(downloadManagerProvider).enqueue(
            DownloadRequest(
              recordKey: params.recordKey,
              subjectId: params.subjectId,
              sourceName: params.sourceName,
              episodeUrl: normalizedEpisodeUrl,
              networkMediaUrl: mediaUrl,
              httpHeaders: await _buildHeaders(
                params.sourceBaseUrl,
                normalizedEpisodeUrl,
                params.sourceName,
              ),
              episode: episode,
            ),
          );
      _refresh();
    } catch (error) {
      if (error is VideoSourceCancelledException) {
        episode.status = DownloadStatus.paused;
      } else {
        episode
          ..status = DownloadStatus.failed
          ..errorMessage = error.toString();
      }
      await repository.updateEpisode(
        params.recordKey,
        normalizedEpisodeUrl,
        episode,
      );
      _refresh();
    }
  }

  Future<void> startDownloads(List<StartDownloadParams> paramsList) async {
    for (final params in paramsList) {
      await startDownload(params);
    }
  }

  Future<void> pause(String recordKey, String episodeUrl) async {
    ref.read(downloadManagerProvider).pause(recordKey, episodeUrl);
    final repository = ref.read(downloadRepositoryProvider);
    final episode = repository.getEpisodeByRecordKey(recordKey, episodeUrl);
    if (episode == null || episode.status == DownloadStatus.completed) {
      _refresh(speed: 0);
      return;
    }
    episode.status = DownloadStatus.paused;
    await repository.updateEpisode(recordKey, episodeUrl, episode);
    _refresh(speed: 0);
  }

  void cancel(String recordKey, String episodeUrl) {
    ref.read(downloadManagerProvider).cancel(recordKey, episodeUrl);
    _refresh();
  }

  Future<void> deleteEpisode(String recordKey, String episodeUrl) async {
    final manager = ref.read(downloadManagerProvider);
    final repository = ref.read(downloadRepositoryProvider);
    final record = repository.getRecord(recordKey);
    final episode = record?.episodes[episodeUrl];
    manager.cancel(recordKey, episodeUrl);
    await manager.deleteEpisodeFiles(episode);
    await repository.deleteEpisode(
      recordKey,
      episodeUrl,
    );
    _refresh(speed: 0);
  }

  Future<void> resume(StartDownloadParams params) {
    return startDownload(params);
  }

  Future<void> downloadDanmaku(String recordKey, String episodeUrl) async {
    final episode = ref
        .read(downloadRepositoryProvider)
        .getEpisodeByRecordKey(recordKey, episodeUrl);
    if (episode == null || episode.status != DownloadStatus.completed) {
      return;
    }
    await _downloadDanmakuIfNeeded(
      recordKey,
      episodeUrl,
      episode,
      force: true,
    );
  }

  Future<void> _downloadDanmakuIfNeeded(
    String recordKey,
    String episodeUrl,
    DownloadEpisode episode, {
    bool force = false,
  }) async {
    final taskKey = _taskKey(recordKey, episodeUrl);
    final shouldDownload =
        force || (_downloadDanmakuByTask[taskKey] ?? _downloadDanmakuEnabled);
    if (!shouldDownload || (episode.danmakuDownloaded && !force)) {
      _downloadDanmakuByTask.remove(taskKey);
      return;
    }
    if (_runningDanmakuTasks.contains(taskKey)) {
      return;
    }

    _runningDanmakuTasks.add(taskKey);
    try {
      final result = await ref.read(downloadDanmakuServiceProvider).download(
            subjectId: ref
                    .read(downloadRepositoryProvider)
                    .getRecord(recordKey)
                    ?.subjectId ??
                0,
            episode: episode,
          );
      if (result != null) {
        episode
          ..danDanBangumiID = result.danDanBangumiId
          ..danmakuDownloaded = result.hasDanmaku
          ..localDanmakuPath = result.localPath;
      } else {
        episode
          ..danmakuDownloaded = false
          ..localDanmakuPath = '';
      }
    } catch (_) {
      episode
        ..danmakuDownloaded = false
        ..localDanmakuPath = '';
    } finally {
      _runningDanmakuTasks.remove(taskKey);
      _downloadDanmakuByTask.remove(taskKey);
      await ref.read(downloadRepositoryProvider).updateEpisode(
            recordKey,
            episodeUrl,
            episode,
          );
      _refresh(speed: 0);
    }
  }

  Future<String> _resolveNetworkMediaUrl(
    String episodeUrl, {
    required bool useLegacyParser,
  }) async {
    final source = await ref.read(videoSourceResolverPoolProvider).resolve(
          VideoSourceResolveRequest(
            episodeUrl: episodeUrl,
            useLegacyParser: useLegacyParser,
          ),
        );
    return source.url;
  }

  Future<Map<String, String>> _buildHeaders(
    String sourceBaseUrl,
    String episodeUrl,
    String sourceName,
  ) async {
    final cookie = await _cookieHeaderFor(episodeUrl, sourceName);
    return {
      'referer': '${sourceBaseUrl.replaceAll(RegExp(r'/+$'), '')}/',
      'accept-language': Utils.getRandomAcceptedLanguage(),
      'connection': 'keep-alive',
      Constants.userAgentName: Utils.getRandomUA(),
      if (cookie.isNotEmpty) 'Cookie': cookie,
    };
  }

  Future<String> _cookieHeaderFor(String url, String name) async {
    if (!CookieManager.instance.hasCookies(name)) {
      return '';
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return '';
    }
    try {
      final cookies =
          await CookieManager.instance.getJar(name).loadForRequest(uri);
      return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join(
            '; ',
          );
    } catch (_) {
      return '';
    }
  }

  void _refresh({double? speed}) {
    final currentSpeed = speed ?? state.currentSpeed;
    state = _buildState(
      ref.read(downloadRepositoryProvider).getAllRecords(),
      speed: currentSpeed,
    );
  }

  Future<void> _resetIncompleteDownloads() async {
    final repository = ref.read(downloadRepositoryProvider);
    var changed = false;
    final records = repository.getAllRecords();
    for (final record in records) {
      var recordChanged = false;
      final episodes = Map<String, DownloadEpisode>.from(record.episodes);
      for (final entry in episodes.entries) {
        final episode = entry.value;
        if (_isIncompleteStatus(episode.status)) {
          episode.status = DownloadStatus.paused;
          recordChanged = true;
          changed = true;
        }
      }
      if (recordChanged) {
        record.episodes = episodes;
        await repository.putRecord(record);
      }
    }
    if (changed) {
      _refresh(speed: 0);
    }
  }

  bool _isIncompleteStatus(int status) {
    return status == DownloadStatus.resolving ||
        status == DownloadStatus.pending ||
        status == DownloadStatus.downloading;
  }

  DownloadState _buildState(
    List<DownloadRecord> records, {
    double? speed,
  }) {
    final episodes = records.expand((record) => record.episodes.values);
    final totalTasks = episodes.length;
    final completedTasks = episodes
        .where((episode) => episode.status == DownloadStatus.completed)
        .length;
    return DownloadState(
      records: records,
      currentSpeed: speed ?? 0,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
    );
  }

  String _resolveEpisodeUrl(String baseUrl, String episodeUrl) {
    final uri = Uri.tryParse(episodeUrl);
    if (uri != null && uri.hasScheme) {
      return episodeUrl;
    }
    return Uri.parse(baseUrl).resolve(episodeUrl).toString();
  }

  bool get _downloadDanmakuEnabled {
    try {
      return Storage.setting.get(
        DownloadKey.downloadDanmaku,
        defaultValue: true,
      );
    } catch (_) {
      return true;
    }
  }

  static String _taskKey(String recordKey, String episodeUrl) {
    return '$recordKey::$episodeUrl';
  }

  bool _isEpisodePaused(String recordKey, String episodeUrl) {
    return ref
            .read(downloadRepositoryProvider)
            .getEpisodeByRecordKey(recordKey, episodeUrl)
            ?.status ==
        DownloadStatus.paused;
  }
}

extension on IDownloadRepository {
  DownloadEpisode? getEpisodeByRecordKey(String recordKey, String episodeUrl) {
    final record = getRecord(recordKey);
    return record?.episodes[episodeUrl];
  }
}

import 'dart:async';
import 'dart:io';

import 'package:anime_flow/features/download/application/download_http_client.dart';
import 'package:anime_flow/features/download/application/m3u8_parser.dart';
import 'package:anime_flow/features/download/data/repositories/download_repository.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DownloadRequest {
  const DownloadRequest({
    required this.recordKey,
    required this.subjectId,
    required this.sourceName,
    required this.episodeUrl,
    required this.networkMediaUrl,
    required this.httpHeaders,
    required this.episode,
    this.adBlockerEnabled = false,
  });

  final String recordKey;
  final int subjectId;
  final String sourceName;
  final String episodeUrl;
  final String networkMediaUrl;
  final Map<String, String> httpHeaders;
  final bool adBlockerEnabled;
  final DownloadEpisode episode;
}

typedef DownloadProgressCallback = void Function(
  String recordKey,
  String episodeUrl,
  DownloadEpisode episode,
  double speed,
);

abstract interface class IDownloadManager {
  DownloadProgressCallback? onProgress;

  int get maxParallelEpisodes;
  set maxParallelEpisodes(int value);

  int get maxParallelSegments;
  set maxParallelSegments(int value);

  bool isDownloading(String recordKey, String episodeUrl);

  double getSpeed(String recordKey, String episodeUrl);

  Future<void> enqueue(DownloadRequest request);

  Future<void> enqueuePriority(DownloadRequest request);

  Future<void> resume(DownloadRequest request);

  void pause(String recordKey, String episodeUrl);

  void cancel(String recordKey, String episodeUrl);

  String? getLocalMediaPath(DownloadEpisode? episode);

  Future<void> deleteEpisodeFiles(DownloadEpisode? episode);
}

class DownloadManager implements IDownloadManager {
  DownloadManager({
    DownloadHttpClient? httpClient,
    IDownloadRepository? repository,
    Future<String> Function()? baseDirectoryProvider,
    this.maxParallelEpisodes = 2,
    this.maxParallelSegments = 3,
  })  : _httpClient = httpClient ?? DownloadHttpClient(),
        _repository = repository,
        _baseDirectoryProvider =
            baseDirectoryProvider ?? _defaultBaseDirectoryProvider;

  final DownloadHttpClient _httpClient;
  final IDownloadRepository? _repository;
  final Future<String> Function() _baseDirectoryProvider;

  @override
  DownloadProgressCallback? onProgress;

  @override
  int maxParallelEpisodes;

  @override
  int maxParallelSegments;

  final _activeTasks = <String, _DownloadTask>{};
  final _queue = <DownloadRequest>[];
  final _speedTrackers = <String, _SpeedTracker>{};
  var _runningCount = 0;

  @override
  bool isDownloading(String recordKey, String episodeUrl) {
    return _activeTasks.containsKey(_taskKey(recordKey, episodeUrl));
  }

  @override
  double getSpeed(String recordKey, String episodeUrl) {
    return _speedTrackers[_taskKey(recordKey, episodeUrl)]?.currentSpeed ?? 0;
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    final key = _taskKey(request.recordKey, request.episodeUrl);
    if (_activeTasks.containsKey(key)) {
      return;
    }

    final task = _DownloadTask(request: request);
    _activeTasks[key] = task;

    if (_runningCount < maxParallelEpisodes) {
      _startTask(task);
      return;
    }

    request.episode.status = DownloadStatus.pending;
    await _persistAndNotify(request, speed: 0);
    _queue.add(request);
  }

  @override
  Future<void> enqueuePriority(DownloadRequest request) async {
    final key = _taskKey(request.recordKey, request.episodeUrl);
    _queue.removeWhere((item) => _requestKey(item) == key);
    _activeTasks.remove(key)?.cancel();

    final task = _DownloadTask(request: request);
    _activeTasks[key] = task;
    _startTask(task);
  }

  @override
  Future<void> resume(DownloadRequest request) async {
    final key = _taskKey(request.recordKey, request.episodeUrl);
    _activeTasks.remove(key);
    await enqueue(request);
  }

  @override
  void pause(String recordKey, String episodeUrl) {
    final key = _taskKey(recordKey, episodeUrl);
    final task = _activeTasks[key];
    if (task == null) {
      return;
    }
    task.pause();
  }

  @override
  void cancel(String recordKey, String episodeUrl) {
    final key = _taskKey(recordKey, episodeUrl);
    _queue.removeWhere((request) => _requestKey(request) == key);
    _activeTasks.remove(key)?.cancel();
    _speedTrackers.remove(key);
  }

  @override
  String? getLocalMediaPath(DownloadEpisode? episode) {
    if (episode == null || episode.status != DownloadStatus.completed) {
      return null;
    }
    if (episode.localMediaPath.isEmpty) {
      return null;
    }
    return File(episode.localMediaPath).existsSync()
        ? episode.localMediaPath
        : null;
  }

  @override
  Future<void> deleteEpisodeFiles(DownloadEpisode? episode) async {
    if (episode == null) {
      return;
    }
    final downloadDirectory = episode.downloadDirectory.trim();
    if (downloadDirectory.isEmpty) {
      return;
    }
    final directory = Directory(downloadDirectory);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  void _startTask(_DownloadTask task) {
    unawaited(_runTask(task));
    _runningCount++;
  }

  Future<void> _runTask(_DownloadTask task) async {
    final request = task.request;
    final key = _requestKey(request);
    final speedTracker = _SpeedTracker();
    _speedTrackers[key] = speedTracker;

    try {
      final episode = request.episode;
      episode
        ..status = DownloadStatus.downloading
        ..networkMediaUrl = request.networkMediaUrl
        ..errorMessage = '';
      episode.downloadDirectory = await _prepareEpisodeDirectory(request);
      await _persistAndNotify(request, speed: speedTracker.currentSpeed);

      final playlistContent = await _fetchPlaylistOrNull(request, task);
      if (playlistContent == null) {
        await _downloadDirect(request, task, speedTracker);
      } else {
        await _downloadM3u8(request, task, playlistContent, speedTracker);
      }
    } on _DownloadPaused {
      request.episode.status = DownloadStatus.paused;
      await _persistAndNotify(request, speed: 0);
    } on _DownloadCancelled {
      // Canceled tasks are removed from the active map without changing
      // persisted state. Explicit delete/cancel UI can decide what to show.
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel && task.isStopped) {
        if (task.isPaused) {
          request.episode.status = DownloadStatus.paused;
          await _persistAndNotify(request, speed: 0);
        }
        return;
      }
      request.episode
        ..status = DownloadStatus.failed
        ..errorMessage = error.toString();
      await _persistAndNotify(request, speed: 0);
    } catch (error) {
      request.episode
        ..status = DownloadStatus.failed
        ..errorMessage = error.toString();
      await _persistAndNotify(request, speed: 0);
    } finally {
      _activeTasks.remove(key);
      _speedTrackers.remove(key);
      _runningCount = _runningCount > 0 ? _runningCount - 1 : 0;
      _processQueue();
    }
  }

  Future<void> _downloadM3u8(
    DownloadRequest request,
    _DownloadTask task,
    String playlistContent,
    _SpeedTracker speedTracker,
  ) async {
    var mediaContent = playlistContent;
    var mediaUrl = request.networkMediaUrl;

    if (M3u8Parser.detectType(playlistContent) == M3u8Type.master) {
      final master = M3u8Parser.parseMasterPlaylist(
        playlistContent,
        request.networkMediaUrl,
      );
      mediaUrl = master.bestVariant.uri;
      mediaContent = await _fetchPlaylistText(mediaUrl, request, task);
    }

    final playlist = M3u8Parser.parseMediaPlaylist(mediaContent, mediaUrl);
    final resolvedSegments = await M3u8Parser.resolveNestedSegments(
      playlist.segments,
      (url) => _fetchPlaylistText(url, request, task),
    );
    if (!playlist.isVod || resolvedSegments.isEmpty) {
      throw StateError('不支持下载直播流或空 M3U8 播放列表');
    }

    final episode = request.episode;
    final episodeDir = episode.downloadDirectory;
    episode
      ..mediaType = 'm3u8'
      ..totalSegments = resolvedSegments.length
      ..downloadedSegments = 0
      ..progressPercent = 0;
    await _persistAndNotify(request, speed: speedTracker.currentSpeed);

    final keyUriToLocal = await _downloadKeys(
      resolvedSegments,
      episodeDir,
      request,
      task,
    );

    var existingBytes = 0;
    final pendingIndices = <int>[];
    for (var i = 0; i < resolvedSegments.length; i++) {
      final segmentPath = _segmentPath(episodeDir, i);
      final segmentFile = File(segmentPath);
      if (await segmentFile.exists() && await segmentFile.length() > 0) {
        episode.downloadedSegments++;
        existingBytes += await segmentFile.length();
      } else {
        pendingIndices.add(i);
      }
    }

    episode
      ..totalBytes = existingBytes
      ..progressPercent = episode.totalSegments == 0
          ? 0
          : episode.downloadedSegments / episode.totalSegments * 100;
    await _persistAndNotify(request, speed: speedTracker.currentSpeed);

    var sessionBytes = 0;
    final semaphore = _Semaphore(maxParallelSegments);
    final failures = <Object>[];

    await Future.wait(
      pendingIndices.map((index) async {
        await semaphore.acquire();
        try {
          task.throwIfStopped();
          final bytes = await _downloadSegmentWithRetry(
            resolvedSegments[index].uri,
            _segmentPath(episodeDir, index),
            request,
            task,
          );
          sessionBytes += bytes;
          episode
            ..downloadedSegments = episode.downloadedSegments + 1
            ..totalBytes = existingBytes + sessionBytes
            ..progressPercent =
                episode.downloadedSegments / episode.totalSegments * 100;
          speedTracker.update(sessionBytes);
          await _persistAndNotify(request, speed: speedTracker.currentSpeed);
        } catch (error) {
          failures.add(error);
        } finally {
          semaphore.release();
        }
      }),
    );

    task.throwIfStopped();
    if (failures.isNotEmpty) {
      throw StateError('${failures.length} 个分片下载失败');
    }

    final localPlaylistPath = p.join(episodeDir, 'playlist.m3u8');
    await File(localPlaylistPath).writeAsString(
      M3u8Parser.buildLocalM3u8(
        resolvedSegments,
        targetDuration: playlist.targetDuration,
        keyUriToLocal: keyUriToLocal,
      ),
    );

    episode
      ..status = DownloadStatus.completed
      ..progressPercent = 100
      ..localMediaPath = localPlaylistPath
      ..completedAt = DateTime.now();
    await _persistAndNotify(request, speed: 0);
  }

  Future<void> _downloadDirect(
    DownloadRequest request,
    _DownloadTask task,
    _SpeedTracker speedTracker,
  ) async {
    final episode = request.episode;
    final episodeDir = episode.downloadDirectory;
    final filePath = p.join(episodeDir, 'video.mp4');
    final tmpPath = '$filePath.tmp';
    final tmpFile = File(tmpPath);

    var existingBytes = 0;
    if (await tmpFile.exists()) {
      existingBytes = await tmpFile.length();
    }

    var headers = _directDownloadHeaders(request.httpHeaders);
    if (existingBytes > 0) {
      headers['Range'] = 'bytes=$existingBytes-';
    }

    Response<ResponseBody> response;
    try {
      response = await _httpClient.getStream(
        request.networkMediaUrl,
        headers: headers,
        cancelToken: task.cancelToken,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode ==
              HttpStatus.requestedRangeNotSatisfiable &&
          existingBytes > 0) {
        await tmpFile.delete();
        existingBytes = 0;
        headers.remove('Range');
        response = await _httpClient.getStream(
          request.networkMediaUrl,
          headers: headers,
          cancelToken: task.cancelToken,
        );
      } else if (_shouldRetryWithoutReferer(error, headers)) {
        headers = _withoutReferer(headers);
        if (existingBytes > 0) {
          headers['Range'] = 'bytes=$existingBytes-';
        }
        response = await _httpClient.getStream(
          request.networkMediaUrl,
          headers: headers,
          cancelToken: task.cancelToken,
        );
      } else {
        rethrow;
      }
    }

    final totalSize = _totalSize(response, existingBytes);
    episode
      ..mediaType = 'direct'
      ..totalSegments = 1
      ..downloadedSegments = existingBytes > 0 ? 0 : 0
      ..totalBytes = existingBytes
      ..progressPercent = totalSize > 0 ? existingBytes / totalSize * 100 : 0;
    await _persistAndNotify(request, speed: speedTracker.currentSpeed);

    final sink = tmpFile.openWrite(
      mode: existingBytes > 0 ? FileMode.append : FileMode.write,
    );
    var received = existingBytes;

    try {
      await for (final chunk in response.data!.stream) {
        task.throwIfStopped();
        sink.add(chunk);
        received += chunk.length;
        episode
          ..totalBytes = received
          ..progressPercent = totalSize > 0 ? received / totalSize * 100 : 0;
        speedTracker.update(received);
        await _persistAndNotify(request, speed: speedTracker.currentSpeed);
      }
    } finally {
      await sink.close();
    }

    task.throwIfStopped();
    if (await File(filePath).exists()) {
      await File(filePath).delete();
    }
    await tmpFile.rename(filePath);

    episode
      ..status = DownloadStatus.completed
      ..downloadedSegments = 1
      ..progressPercent = 100
      ..localMediaPath = filePath
      ..completedAt = DateTime.now();
    await _persistAndNotify(request, speed: 0);
  }

  Future<Map<String, String>> _downloadKeys(
    List<M3u8Segment> segments,
    String episodeDir,
    DownloadRequest request,
    _DownloadTask task,
  ) async {
    final keys = M3u8Parser.extractUniqueKeys(
      M3u8MediaPlaylist(
        segments: segments,
        targetDuration: 0,
        isVod: true,
      ),
    );
    final keyUriToLocal = <String, String>{};

    for (var i = 0; i < keys.length; i++) {
      task.throwIfStopped();
      final fileName = 'key_$i.key';
      await _httpClient.download(
        keys[i].uri,
        p.join(episodeDir, fileName),
        headers: request.httpHeaders,
        cancelToken: task.cancelToken,
      );
      keyUriToLocal[keys[i].uri] = fileName;
    }

    return keyUriToLocal;
  }

  Future<int> _downloadSegmentWithRetry(
    String url,
    String savePath,
    DownloadRequest request,
    _DownloadTask task, {
    int maxRetries = 3,
  }) async {
    final tmpPath = '$savePath.tmp';
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        task.throwIfStopped();
        await _httpClient.download(
          url,
          tmpPath,
          headers: request.httpHeaders,
          cancelToken: task.cancelToken,
        );
        final tmpFile = File(tmpPath);
        if (await File(savePath).exists()) {
          await File(savePath).delete();
        }
        await tmpFile.rename(savePath);
        return await File(savePath).length();
      } catch (error) {
        if (await File(tmpPath).exists()) {
          await File(tmpPath).delete();
        }
        task.throwIfStopped();
        if (attempt == maxRetries - 1) {
          rethrow;
        }
        await Future<void>.delayed(Duration(seconds: [1, 3, 9][attempt]));
      }
    }

    throw StateError('分片下载失败');
  }

  Future<String?> _fetchPlaylistOrNull(
    DownloadRequest request,
    _DownloadTask task,
  ) async {
    if (!_looksLikeM3u8Url(request.networkMediaUrl)) {
      return null;
    }

    try {
      final content = await _fetchPlaylistText(
        request.networkMediaUrl,
        request,
        task,
      );
      return content.trimLeft().startsWith('#EXTM3U') ? content : null;
    } on DioException {
      rethrow;
    } on _DownloadPaused {
      rethrow;
    } on _DownloadCancelled {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<String> _fetchPlaylistText(
    String url,
    DownloadRequest request,
    _DownloadTask task,
  ) async {
    final fetchToken = CancelToken();
    final content = await _httpClient.getPlain(
      url,
      headers: request.httpHeaders,
      cancelToken: fetchToken,
      onReceiveProgress: (received, _) {
        if (task.isStopped) {
          fetchToken.cancel('download stopped');
        }
        if (received > 2 * 1024 * 1024) {
          fetchToken.cancel('playlist response too large');
        }
      },
    );
    task.throwIfStopped();
    return content;
  }

  Map<String, String> _directDownloadHeaders(Map<String, String> headers) {
    return {
      ...headers,
      'accept': headers['accept'] ?? headers['Accept'] ?? '*/*',
    };
  }

  bool _shouldRetryWithoutReferer(
    DioException error,
    Map<String, String> headers,
  ) {
    final status = error.response?.statusCode;
    if (status != HttpStatus.badRequest && status != HttpStatus.forbidden) {
      return false;
    }
    return headers.keys.any((key) => key.toLowerCase() == 'referer');
  }

  Map<String, String> _withoutReferer(Map<String, String> headers) {
    return Map<String, String>.fromEntries(
      headers.entries.where((entry) {
        final key = entry.key.toLowerCase();
        return key != 'referer' && key != 'origin';
      }),
    );
  }

  bool _looksLikeM3u8Url(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return url.toLowerCase().contains('.m3u8');
    }
    final path = uri.path.toLowerCase();
    if (path.endsWith('.m3u8')) {
      return true;
    }
    return uri.query.toLowerCase().contains('m3u8');
  }

  Future<String> _prepareEpisodeDirectory(DownloadRequest request) async {
    final existing = request.episode.downloadDirectory.trim();
    final directory = existing.isNotEmpty
        ? existing
        : p.join(
            await _baseDirectoryProvider(),
            '${request.sourceName}_${request.subjectId}',
            request.episode.episodeIndex.toString(),
          );
    await Directory(directory).create(recursive: true);
    return directory;
  }

  Future<void> _persistAndNotify(
    DownloadRequest request, {
    required double speed,
  }) async {
    await _repository?.updateEpisode(
      request.recordKey,
      request.episodeUrl,
      request.episode,
    );
    onProgress?.call(
      request.recordKey,
      request.episodeUrl,
      request.episode,
      speed,
    );
  }

  void _processQueue() {
    while (_runningCount < maxParallelEpisodes && _queue.isNotEmpty) {
      final request = _queue.removeAt(0);
      final key = _requestKey(request);
      final task = _activeTasks[key];
      if (task == null || task.isStopped) {
        _activeTasks.remove(key);
        continue;
      }
      _startTask(task);
    }
  }

  static Future<String> _defaultBaseDirectoryProvider() async {
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, 'downloads');
  }

  static Future<String> getDefaultDownloadDirectory() {
    return _defaultBaseDirectoryProvider();
  }

  static String _taskKey(String recordKey, String episodeUrl) {
    return '$recordKey::$episodeUrl';
  }

  static String _requestKey(DownloadRequest request) {
    return _taskKey(request.recordKey, request.episodeUrl);
  }

  static String _segmentPath(String episodeDir, int index) {
    return p.join(episodeDir, 'seg_${index.toString().padLeft(5, '0')}.ts');
  }

  static int _totalSize(Response<ResponseBody> response, int existingBytes) {
    final contentRange = response.headers.value('content-range');
    if (contentRange != null) {
      final match = RegExp(r'/(\d+)$').firstMatch(contentRange);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    }

    final contentLength = int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        0;
    return existingBytes + contentLength;
  }
}

class _DownloadTask {
  _DownloadTask({required this.request});

  final DownloadRequest request;
  final CancelToken cancelToken = CancelToken();
  var isPaused = false;
  var isCancelled = false;

  bool get isStopped => isPaused || isCancelled || cancelToken.isCancelled;

  void pause() {
    isPaused = true;
    cancelToken.cancel('paused');
  }

  void cancel() {
    isCancelled = true;
    cancelToken.cancel('cancelled');
  }

  void throwIfStopped() {
    if (isPaused) {
      throw const _DownloadPaused();
    }
    if (isCancelled || cancelToken.isCancelled) {
      throw const _DownloadCancelled();
    }
  }
}

class _SpeedTracker {
  var _lastBytes = 0;
  var _lastTime = DateTime.now();
  var currentSpeed = 0.0;

  void update(int totalBytes) {
    final now = DateTime.now();
    final elapsed = now.difference(_lastTime).inMilliseconds;
    if (elapsed < 500) {
      return;
    }

    currentSpeed = (totalBytes - _lastBytes) / (elapsed / 1000);
    _lastBytes = totalBytes;
    _lastTime = now;
  }
}

class _Semaphore {
  _Semaphore(this.maxCount);

  final int maxCount;
  var _currentCount = 0;
  final _waitQueue = <Completer<void>>[];

  Future<void> acquire() {
    if (_currentCount < maxCount) {
      _currentCount++;
      return Future<void>.value();
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeAt(0).complete();
      return;
    }
    _currentCount--;
  }
}

class _DownloadPaused implements Exception {
  const _DownloadPaused();
}

class _DownloadCancelled implements Exception {
  const _DownloadCancelled();
}

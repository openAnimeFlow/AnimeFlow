import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:anime_flow/features/download/application/m3u8_parser.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';

import '../domain/hls_snapshot.dart';
import '../infrastructure/media_http_fetcher.dart';

enum CacheReadPriority { playback, export }

/// Application-owned, bounded HLS cache. Each resolved source has independent
/// authentication, resource identity and references. Playback release does not
/// destroy resources still retained by an export lease or an HTTP reader.
class HlsMediaCache {
  HlsMediaCache(
      {required this.directory,
      this.capacityBytes = 256 * 1024 * 1024,
      this.maxSegmentBytes = 32 * 1024 * 1024,
      this.maxDownloads = 3,
      MediaHttpFetcher? fetcher})
      : _fetcher = fetcher ?? MediaHttpFetcher() {
    if (capacityBytes < maxSegmentBytes ||
        maxSegmentBytes < 564 ||
        maxDownloads < 2) {
      throw ArgumentError('Invalid cache limits');
    }
  }
  final Directory directory;
  final int capacityBytes;
  final int maxSegmentBytes;
  final int maxDownloads;
  final MediaHttpFetcher _fetcher;
  final _lock = Lock();
  final _sessions = <String, HlsCacheSession>{};
  final _queue = <_Download>[];
  final _pendingOperations = <Future<void>>{};
  HttpServer? _server;
  Future<void>? _initializing;
  RandomAccessFile? _directoryLock;
  bool _closed = false;
  int _used = 0;
  int _reserved = 0;
  int _active = 0;
  int _background = 0;
  int get cachedBytes => _used;

  Future<void> _initialize() => _initializing ??= () async {
        try {
          await directory.create(recursive: true);
          _directoryLock = await File(p.join(directory.path, '.lock'))
              .open(mode: FileMode.append);
          await _directoryLock!.lock(FileLock.exclusive);
          // No persisted tasks exist in phase 1. Remove only our abandoned session
          // directories, never following links or touching another cache process.
          await for (final entry in directory.list(followLinks: false)) {
            if (entry is Directory &&
                RegExp(r'^[0-9a-f]{48}$').hasMatch(p.basename(entry.path)) &&
                p.isWithin(directory.absolute.path, entry.absolute.path)) {
              await entry.delete(recursive: true);
            }
          }
          _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          _server!.listen((request) => _track(_serve(request)));
        } catch (_) {
          await _directoryLock?.close();
          _directoryLock = null;
          _initializing = null;
          rethrow;
        }
      }();

  Future<HlsCacheSession> open(PlaybackSource source) async {
    if (_closed) throw StateError('Cache closed');
    HlsSnapshot.checkHttpUri(source.uri);
    await _initialize();
    final snapshotSource = PlaybackSource(
        uri: source.uri,
        headers: Map.unmodifiable(source.headers),
        referer: source.referer,
        userAgent: source.userAgent,
        subtitle: source.subtitle);
    final headers = <String, String>{
      for (final e in snapshotSource.headers.entries)
        e.key.toLowerCase(): e.value,
      if (source.referer != null) 'referer': source.referer!,
      if (source.userAgent != null) 'user-agent': source.userAgent!,
    };
    var response = await _fetcher.get(source.uri,
        credentialOrigin: source.uri, headers: headers, limit: 1024 * 1024);
    var content = utf8.decode(response.bytes);
    if (M3u8Parser.detectType(content) == M3u8Type.master) {
      HlsSnapshot.checkedLines(content, master: true);
      final master =
          M3u8Parser.parseMasterPlaylist(content, response.uri.toString());
      if (master.variants.isEmpty ||
          master.variants.any((v) => v.audioGroupId != null)) {
        HlsSnapshot.unsupported();
      }
      final variant = Uri.parse(master.bestVariant.uri);
      HlsSnapshot.checkHttpUri(variant);
      response = await _fetcher.get(variant,
          credentialOrigin: source.uri, headers: headers, limit: 1024 * 1024);
      content = utf8.decode(response.bytes);
    }
    final timeline = HlsSnapshot.parse(content, response.uri);
    if (_closed) throw StateError('Cache closed');
    final token = _token();
    final folder = await Directory(p.join(directory.path, token)).create();
    final session = HlsCacheSession._(this, token, folder, snapshotSource,
        Map.unmodifiable(headers), timeline);
    _sessions[token] = session;
    try {
      // Establish supported transport and capacity before replacing the source.
      await session.withSegment(0, (_) async {});
      return session;
    } catch (_) {
      await session.releasePlayback();
      rethrow;
    }
  }

  Uri _uri(String token, String resource) => Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: _server!.port,
      path: '/$token/$resource');
  static String _token() {
    final random = Random.secure();
    return List.generate(
            24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<File> _read(_Segment resource, CacheReadPriority priority) async {
    final session = resource.session;
    session._check();
    resource.lastRead = DateTime.now();
    if (resource.file != null && DateTime.now().isBefore(resource.expires)) {
      return resource.file!;
    }
    var download = resource.download;
    if (download == null) {
      download = _Download(resource, priority);
      resource.download = download;
      _queue.add(download);
    } else if (priority == CacheReadPriority.playback) {
      download.priority = priority; // Promote a shared queued export request.
    }
    _pump();
    return download.result.future;
  }

  void _pump() {
    while (!_closed && _active < maxDownloads && _queue.isNotEmpty) {
      var index =
          _queue.indexWhere((d) => d.priority == CacheReadPriority.playback);
      if (index < 0) {
        // Reserve a slot for playback and permit only one background transfer.
        if (_background != 0 || _active >= maxDownloads - 1) return;
        index = 0;
      }
      final download = _queue.removeAt(index);
      final background = download.priority == CacheReadPriority.export;
      _active++;
      if (background) _background++;
      _track(_runDownload(download, background));
    }
  }

  void _track(Future<void> operation) {
    _pendingOperations.add(operation);
    unawaited(operation.then<void>((_) {
      _pendingOperations.remove(operation);
    }, onError: (Object error, StackTrace stack) {
      _pendingOperations.remove(operation);
    }));
  }

  Future<void> _reserve() => _lock.synchronized(() async {
        while (_used + _reserved + maxSegmentBytes > capacityBytes) {
          final candidates = _sessions.values
              .expand((s) => s._resources.values)
              .where((r) =>
                  r.file != null &&
                  r.readers == 0 &&
                  r.pins == 0 &&
                  r.download == null)
              .toList()
            ..sort((a, b) => a.lastRead.compareTo(b.lastRead));
          if (candidates.isEmpty) {
            throw const MediaCacheException(
                MediaCacheIssue.capacity, '共享缓存空间不足，请释放保留片段或关闭共享缓存');
          }
          final victim = candidates.first;
          await victim.file!.delete();
          victim.file = null;
          _used -= victim.size;
        }
        _reserved += maxSegmentBytes;
      });

  Future<void> _runDownload(_Download download, bool background) async {
    final resource = download.resource;
    var reserved = false;
    File? partial;
    try {
      resource.session._check();
      await _reserve();
      reserved = true;
      final response = await _fetcher.get(resource.uri,
          credentialOrigin: resource.session.source.uri,
          headers: resource.session._headers,
          limit: maxSegmentBytes);
      resource.session._check();
      final bytes = response.bytes;
      // Stage 1 is MPEG-TS only; fMP4, packed audio and nested playlists are not
      // disguised as .ts and passed to the player/FFmpeg.
      if (bytes.length < 564 ||
          bytes[0] != 0x47 ||
          bytes[188] != 0x47 ||
          bytes[376] != 0x47) {
        HlsSnapshot.unsupported();
      }
      final digest = sha256.convert(bytes).toString();
      if (resource.digest != null && resource.digest != digest) {
        resource.session._invalid = true;
        throw const MediaCacheException(
            MediaCacheIssue.sourceChanged, '媒体资源已变化，请重新加载');
      }
      final control = response.headers['cache-control']?.toLowerCase() ?? '';
      if (control.contains('no-store')) {
        throw const MediaCacheException(
            MediaCacheIssue.unsupported, '源站禁止缓存，当前源继续直连播放');
      }
      final maxAge = int.tryParse(RegExp(r'(?:^|,)\s*max-age="?(\d+)"?')
              .firstMatch(control)
              ?.group(1) ??
          '');
      final age = int.tryParse(response.headers['age'] ?? '') ?? 0;
      final seconds = control.contains('no-cache')
          ? 0
          : ((maxAge ?? 300) - age).clamp(0, 3600);
      resource.expires = DateTime.now().add(Duration(seconds: seconds));
      resource.digest = digest;
      if (resource.file == null) {
        partial = File(
            p.join(resource.session.directory.path, '${resource.id}.partial'));
        await partial.writeAsBytes(bytes, flush: true);
        resource.file = await partial.rename(
            p.join(resource.session.directory.path, '${resource.id}.ts'));
        resource.size = bytes.length;
        _used += resource.size;
      }
      download.result.complete(resource.file!);
    } catch (error, stack) {
      try {
        if (partial != null && await partial.exists()) await partial.delete();
      } catch (_) {}
      try {
        resource.session.onIssue?.call(error is MediaCacheException
            ? error.issue
            : MediaCacheIssue.unavailable);
      } catch (_) {/* A UI callback must not strand shared consumers. */}
      download.result.completeError(error, stack);
    } finally {
      if (reserved) _reserved -= maxSegmentBytes;
      resource.download = null;
      _active--;
      if (background) _background--;
      _pump();
    }
  }

  Future<void> _serve(HttpRequest request) async {
    HlsCacheSession? session;
    var retained = false;
    try {
      final parts = request.uri.pathSegments;
      if (_closed ||
          parts.length != 2 ||
          request.uri.hasQuery ||
          !{'GET', 'HEAD'}.contains(request.method)) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      session = _sessions[parts[0]];
      if (session == null || session._references == 0) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      session._check();
      session._references++;
      retained = true;
      request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      final resource = parts[1];
      String? playlist;
      var priority = CacheReadPriority.playback;
      if (resource == 'index.m3u8') {
        playlist = session.timeline.playlist(session.segmentUri);
      }
      if (resource.startsWith('clip-') && resource.endsWith('.m3u8')) {
        final lease = session._leases[resource];
        if (lease != null) {
          playlist = session.timeline.playlist(session.exportSegmentUri,
              first: lease._first, last: lease._last);
        }
      }
      if (playlist != null) {
        final bytes = utf8.encode(playlist);
        request.response.headers.contentType =
            ContentType('application', 'vnd.apple.mpegurl');
        request.response.contentLength = bytes.length;
        if (request.method == 'GET') request.response.add(bytes);
        return;
      }
      final match = RegExp(r'^(export-)?seg-(\d+)\.ts$').firstMatch(resource);
      if (match == null) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      final index = int.tryParse(match.group(2)!);
      if (index == null || index >= session.timeline.segments.length) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      if (match.group(1) != null) priority = CacheReadPriority.export;
      await session.withSegment(index, (file) async {
        final size = await file.length();
        final range =
            _range(request.headers.value(HttpHeaders.rangeHeader), size);
        request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
        if (range == null) {
          request.response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          request.response.headers
              .set(HttpHeaders.contentRangeHeader, 'bytes */$size');
          return;
        }
        final (start, end, partial) = range;
        if (partial) {
          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers
              .set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$size');
        }
        request.response.headers.contentType = ContentType('video', 'mp2t');
        request.response.contentLength = end - start + 1;
        if (request.method == 'GET') {
          await request.response.addStream(file.openRead(start, end + 1));
        }
      }, priority: priority);
    } catch (_) {
      // No remote errors/URLs/headers are sent to clients or ordinary logs.
      try {
        request.response.statusCode = HttpStatus.badGateway;
      } catch (_) {}
    } finally {
      try {
        await request.response.close();
      } catch (_) {}
      if (retained) await session!._release();
    }
  }

  static (int, int, bool)? _range(String? header, int size) {
    if (header == null) return (0, size - 1, false);
    final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(header);
    if (match == null || size == 0) return null;
    final left = int.tryParse(match.group(1)!);
    final right = int.tryParse(match.group(2)!);
    if ((match.group(1)!.isNotEmpty && left == null) ||
        (match.group(2)!.isNotEmpty && right == null)) {
      return null;
    }
    if (left == null && (right == null || right <= 0)) return null;
    final start = left ?? max(0, size - right!);
    final end = left == null ? size - 1 : min(right ?? size - 1, size - 1);
    if (start >= size || end < start) return null;
    return (start, end, true);
  }

  Future<void> _remove(HlsCacheSession session) async {
    await _lock.synchronized(() async {
      // Failed cleanup must remain accounted for, and must not interrupt the
      // next playback source. Zero-reference sessions cannot serve requests.
      try {
        await session.directory.delete(recursive: true);
      } on FileSystemException {
        return;
      }
      for (final resource in session._resources.values) {
        if (resource.file != null) _used -= resource.size;
      }
      _sessions.remove(session.id);
    });
  }

  /// Only for application shutdown/tests. Ordinary playback releases its own ref.
  Future<void> close() async {
    _closed = true;
    _fetcher.close();
    for (final queued in _queue) {
      queued.result.completeError(StateError('Cache closed'));
      queued.resource.download = null;
    }
    _queue.clear();
    await _server?.close(force: true);
    // Closing the listener does not await response handlers. Keep the directory
    // lock until downloads and readers have finished their file cleanup.
    while (_pendingOperations.isNotEmpty) {
      await Future.wait(_pendingOperations.toList());
    }
    await _lock.synchronized(() {});
    await _directoryLock?.close();
  }
}

class HlsCacheSession {
  HlsCacheSession._(this._cache, this.id, this.directory, this.source,
      this._headers, this.timeline) {
    for (var i = 0; i < timeline.segments.length; i++) {
      final uri = Uri.parse(timeline.segments[i].uri);
      final resource = _resources.putIfAbsent(
          uri.toString(), () => _Segment(this, _resources.length, uri));
      _segments.add(resource);
    }
  }
  final HlsMediaCache _cache;
  final String id;
  final Directory directory;
  final PlaybackSource source;
  final Map<String, String> _headers;
  final HlsSnapshot timeline;
  final _resources = <String, _Segment>{};
  final _segments = <_Segment>[];
  final _leases = <String, HlsCacheLease>{};
  int _references = 1;
  bool _playbackReleased = false;
  bool _invalid = false;
  void Function(MediaCacheIssue issue)? onIssue;
  PlaybackSource get playbackSource => PlaybackSource(
      uri: _cache._uri(id, 'index.m3u8'), subtitle: source.subtitle);
  Uri segmentUri(int index) => _cache._uri(id, 'seg-$index.ts');
  Uri exportSegmentUri(int index) => _cache._uri(id, 'export-seg-$index.ts');
  void _check() {
    if (_invalid) {
      throw const MediaCacheException(
          MediaCacheIssue.sourceChanged, '媒体资源已变化，请重新加载');
    }
    if (_references == 0 || _cache._closed) {
      throw StateError('Source session closed');
    }
  }

  Future<T> withSegment<T>(int index, Future<T> Function(File file) read,
      {CacheReadPriority priority = CacheReadPriority.playback}) async {
    _check();
    final resource = _segments[index];
    _references++;
    resource.readers++;
    try {
      return await read(await _cache._read(resource, priority));
    } finally {
      resource.readers--;
      await _release();
    }
  }

  HlsCacheLease retainRange(Duration start, Duration end) {
    _check();
    final lease = HlsCacheLease._(this, start, end);
    _leases[lease._name] = lease;
    _references++;
    return lease;
  }

  Future<void> releasePlayback() async {
    if (_playbackReleased) return;
    _playbackReleased = true;
    await _release();
  }

  Future<void> _release() async {
    _references--;
    if (_references == 0) await _cache._remove(this);
  }
}

class HlsCacheLease {
  HlsCacheLease._(this.session, this.start, Duration end) {
    extend(end);
  }
  final HlsCacheSession session;
  final Duration start;
  final String _name = 'clip-${HlsMediaCache._token()}.m3u8';
  final _pinned = <_Segment>{};
  int _first = 0;
  int _last = 0;
  Duration _end = Duration.zero;
  Duration inputOffset = Duration.zero;
  bool _released = false;
  Uri get playlistUri => session._cache._uri(session.id, _name);
  Duration get relativeStart => start - inputOffset;
  void extend(Duration end) {
    if (_released || end < _end) {
      throw StateError('Cannot shrink or extend a released lease');
    }
    session._check();
    final (first, last, offset) = session.timeline.range(start, end);
    _first = first;
    _last = last;
    inputOffset = offset;
    _end = end;
    for (var i = first; i <= last; i++) {
      if (_pinned.add(session._segments[i])) session._segments[i].pins++;
    }
  }

  Future<void> release() async {
    if (_released) return;
    _released = true;
    for (final resource in _pinned) {
      resource.pins--;
    }
    session._leases.remove(_name);
    await session._release();
  }
}

class _Segment {
  _Segment(this.session, this.id, this.uri);
  final HlsCacheSession session;
  final int id;
  final Uri uri;
  File? file;
  String? digest;
  int size = 0;
  int readers = 0;
  int pins = 0;
  DateTime lastRead = DateTime.now();
  DateTime expires = DateTime.fromMillisecondsSinceEpoch(0);
  _Download? download;
}

class _Download {
  _Download(this.resource, this.priority);
  final _Segment resource;
  CacheReadPriority priority;
  final result = Completer<File>();
}

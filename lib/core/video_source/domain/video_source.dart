import 'dart:async';

enum VideoSourceType { online, cached }

class VideoSource {
  const VideoSource(
      {required this.url, required this.offset, required this.type});
  final String url;
  final int offset;
  final VideoSourceType type;
  @override
  String toString() => 'VideoSource(url: $url, offset: $offset, type: $type)';
}

/// Timeout starts when execution begins; time spent waiting in a pool is excluded.
class VideoSourceResolveRequest {
  const VideoSourceResolveRequest({
    required this.episodeUrl,
    this.useLegacyParser = false,
    this.offset = 0,
    this.timeout = const Duration(seconds: 30),
    this.cancellation,
  });
  final String episodeUrl;
  final bool useLegacyParser;
  final int offset;
  final Duration timeout;
  final VideoSourceCancellation? cancellation;

  VideoSourceResolveRequest withCancellation(VideoSourceCancellation value) =>
      VideoSourceResolveRequest(
          episodeUrl: episodeUrl,
          useLegacyParser: useLegacyParser,
          offset: offset,
          timeout: timeout,
          cancellation: value);
}

/// Request-scoped cancellation, independent of UI, Dio and platform plugins.
class VideoSourceCancellation {
  final _events = StreamController<void>.broadcast(sync: true);
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  Stream<void> get onCancel => _events.stream;
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _events.add(null);
    unawaited(_events.close());
  }
}

class VideoSourceNotFoundException implements Exception {
  const VideoSourceNotFoundException([this.message = 'Video source not found']);
  final String message;
  @override
  String toString() => 'VideoSourceNotFoundException: $message';
}

class VideoSourceTimeoutException implements Exception {
  const VideoSourceTimeoutException(this.timeout);
  final Duration timeout;
  @override
  String toString() =>
      'VideoSourceTimeoutException: Timed out after ${timeout.inSeconds}s';
}

class VideoSourceCancelledException implements Exception {
  const VideoSourceCancelledException();
  @override
  String toString() =>
      'VideoSourceCancelledException: Resolution was cancelled';
}

abstract interface class IVideoSourceProvider {
  Future<VideoSource> resolve(VideoSourceResolveRequest request);
  void cancel();
  Future<void> dispose();
}

typedef VideoSourceProviderFactory = IVideoSourceProvider Function();

abstract interface class IVideoSourceResolverPool {
  Future<VideoSource> resolve(VideoSourceResolveRequest request);
  void cancelAll();
  Future<void> dispose();
}

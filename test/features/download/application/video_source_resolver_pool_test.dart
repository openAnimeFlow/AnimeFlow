import 'dart:async';

import 'package:anime_flow/features/download/application/video_source_resolver_pool.dart';
import 'package:anime_flow/features/play/application/video_source_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoSourceResolverPool', () {
    test('queues resolves when workers are busy', () async {
      final provider = _FakeVideoSourceProvider();
      final pool = VideoSourceResolverPool(
        workerCount: 1,
        providerFactory: () => provider,
      );
      addTearDown(pool.dispose);

      final first = pool.resolve(
        const VideoSourceResolveRequest(episodeUrl: 'https://example.com/1'),
      );
      final second = pool.resolve(
        const VideoSourceResolveRequest(episodeUrl: 'https://example.com/2'),
      );

      await Future<void>.delayed(Duration.zero);
      expect(provider.requestedUrls, ['https://example.com/1']);

      provider.completeNext('https://media.example.com/1.m3u8');
      expect((await first).url, 'https://media.example.com/1.m3u8');

      await Future<void>.delayed(Duration.zero);
      expect(provider.requestedUrls, [
        'https://example.com/1',
        'https://example.com/2',
      ]);

      provider.completeNext('https://media.example.com/2.m3u8');
      expect((await second).url, 'https://media.example.com/2.m3u8');
    });

    test('cancelAll completes queued resolves with cancellation', () async {
      final provider = _FakeVideoSourceProvider();
      final pool = VideoSourceResolverPool(
        workerCount: 1,
        providerFactory: () => provider,
      );
      addTearDown(pool.dispose);

      final first = pool.resolve(
        const VideoSourceResolveRequest(episodeUrl: 'https://example.com/1'),
      );
      final second = pool.resolve(
        const VideoSourceResolveRequest(episodeUrl: 'https://example.com/2'),
      );

      await Future<void>.delayed(Duration.zero);
      pool.cancelAll();

      expect(provider.cancelCount, 1);
      expect(second, throwsA(isA<VideoSourceCancelledException>()));
      provider.completeNext('https://media.example.com/1.m3u8');
      expect((await first).url, 'https://media.example.com/1.m3u8');
    });
  });
}

class _FakeVideoSourceProvider implements IVideoSourceProvider {
  final requestedUrls = <String>[];
  final _pending = <Completer<VideoSource>>[];
  var cancelCount = 0;
  var disposeCount = 0;

  @override
  Future<VideoSource> resolve(
    String episodeUrl, {
    required bool useLegacyParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 30),
  }) {
    requestedUrls.add(episodeUrl);
    final completer = Completer<VideoSource>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext(String url) {
    _pending.removeAt(0).complete(
          VideoSource(url: url, offset: 0, type: VideoSourceType.online),
        );
  }

  @override
  void cancel() {
    cancelCount++;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

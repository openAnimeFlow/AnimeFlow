import 'dart:async';

import 'package:anime_flow/features/download/application/video_source_resolver_pool.dart';
import 'package:anime_flow/core/video_source/domain/video_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoSourceResolverPool', () {
    test('runs two workers concurrently and starts queued work in FIFO order',
        () async {
      final workers = <_FakeVideoSourceProvider>[];
      final pool = VideoSourceResolverPool(providerFactory: () {
        final worker = _FakeVideoSourceProvider();
        workers.add(worker);
        return worker;
      });
      addTearDown(pool.dispose);
      final first =
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '1'));
      final second =
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '2'));
      final third =
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '3'));
      expect(workers.length, 2);
      expect(workers[0].requestedUrls, ['1']);
      expect(workers[1].requestedUrls, ['2']);
      workers[0].completeNext('first');
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(workers[0].requestedUrls, ['1', '3']);
      workers[0].completeNext('third');
      workers[1].completeNext('second');
      expect((await third).url, 'third');
      expect((await second).url, 'second');
    });

    test(
        'timeout retires an unresponsive worker and allows the queue to continue',
        () async {
      final workers = <_FakeVideoSourceProvider>[];
      final pool = VideoSourceResolverPool(
          workerCount: 1,
          providerFactory: () {
            final worker = _FakeVideoSourceProvider();
            workers.add(worker);
            return worker;
          });
      addTearDown(pool.dispose);
      final first = pool.resolve(const VideoSourceResolveRequest(
          episodeUrl: '1', timeout: Duration.zero));
      final second =
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '2'));
      await expectLater(first, throwsA(isA<VideoSourceTimeoutException>()));
      await Future<void>.delayed(Duration.zero);
      expect(workers.length, 2);
      expect(workers[0].disposeCount, 1);
      workers[0].completeNext('stale');
      workers[1].completeNext('current');
      expect((await second).url, 'current');
    });

    test(
        'request cancellation removes queued work without cancelling another request',
        () async {
      final worker = _FakeVideoSourceProvider();
      final pool = VideoSourceResolverPool(
          workerCount: 1, providerFactory: () => worker);
      addTearDown(pool.dispose);
      final cancellation = VideoSourceCancellation();
      final first =
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '1'));
      final second = pool.resolve(VideoSourceResolveRequest(
          episodeUrl: '2', cancellation: cancellation));
      final third =
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '3'));
      final rejected =
          expectLater(second, throwsA(isA<VideoSourceCancelledException>()));
      cancellation.cancel();
      await rejected;
      expect(worker.cancelCount, 0);
      worker.completeNext('first');
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(worker.requestedUrls, ['1', '3']);
      worker.completeNext('third');
      await third;
    });

    test(
        'dispose rejects all outstanding work, releases workers once and prevents new tasks',
        () async {
      final worker = _FakeVideoSourceProvider();
      final pool = VideoSourceResolverPool(
          workerCount: 1, providerFactory: () => worker);
      final first =
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '1'));
      final second =
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '2'));
      final rejected = Future.wait([
        expectLater(first, throwsA(isA<VideoSourceCancelledException>())),
        expectLater(second, throwsA(isA<VideoSourceCancelledException>())),
      ]);
      await pool.dispose();
      await rejected;
      await pool.dispose();
      expect(worker.disposeCount, 1);
      await expectLater(
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '3')),
          throwsStateError);
      expect(worker.requestedUrls, ['1']);
    });

    test(
        'a factory failure is delivered to its caller and does not strand the next task',
        () async {
      var calls = 0;
      final worker = _FakeVideoSourceProvider();
      final pool = VideoSourceResolverPool(providerFactory: () {
        if (calls++ == 0) throw StateError('native startup unavailable');
        return worker;
      });
      addTearDown(pool.dispose);
      await expectLater(
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '1')),
          throwsStateError);
      final next =
          pool.resolve(const VideoSourceResolveRequest(episodeUrl: '2'));
      worker.completeNext('next');
      expect((await next).url, 'next');
    });

    test('queues resolves when workers are busy', () async {
      final provider = _FakeVideoSourceProvider();
      final pool = VideoSourceResolverPool(
        workerCount: 1,
        providerFactory: () => provider,
      );
      addTearDown(pool.dispose);

      final first = pool.resolve(
        const VideoSourceResolveRequest(
            episodeUrl: 'https://example.com/1',
            useLegacyParser: true,
            offset: 42),
      );
      final second = pool.resolve(
        const VideoSourceResolveRequest(episodeUrl: 'https://example.com/2'),
      );

      await Future<void>.delayed(Duration.zero);
      expect(provider.requestedUrls, ['https://example.com/1']);
      expect(provider.requests.single.useLegacyParser, isTrue);
      expect(provider.requests.single.offset, 42);

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

    test(
        'cancelAll rejects active and queued results, including late native success',
        () async {
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
      final firstCheck =
          expectLater(first, throwsA(isA<VideoSourceCancelledException>()));
      final secondCheck =
          expectLater(second, throwsA(isA<VideoSourceCancelledException>()));
      pool.cancelAll();
      await Future.wait([firstCheck, secondCheck]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.cancelCount, 1);
      provider.completeNext('https://media.example.com/1.m3u8');
      await Future<void>.delayed(Duration.zero);
      expect(provider.disposeCount, 1);
    });
  });
}

class _FakeVideoSourceProvider implements IVideoSourceProvider {
  final requests = <VideoSourceResolveRequest>[];
  final requestedUrls = <String>[];
  final _pending = <Completer<VideoSource>>[];
  var cancelCount = 0;
  var disposeCount = 0;

  @override
  Future<VideoSource> resolve(VideoSourceResolveRequest request) {
    requests.add(request);
    requestedUrls.add(request.episodeUrl);
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

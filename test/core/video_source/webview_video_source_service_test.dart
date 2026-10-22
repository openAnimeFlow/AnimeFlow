import 'dart:async';

import 'package:anime_flow/core/video_source/domain/video_source.dart';
import 'package:anime_flow/core/video_source/infrastructure/webview_video_source_service.dart';
import 'package:anime_flow/core/webview/video/video_webview_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class Controller extends VideoWebviewController<Object> {
  Completer<void>? initialization, loading;
  final initialized = Completer<void>();
  var _loaded = Completer<void>();
  final loads = <VideoSourceResolveRequest>[];
  int disposals = 0, unloads = 0;
  @override
  Future<void> init() async {
    initialized.complete();
    await initialization?.future;
  }

  @override
  Future<void> loadUrl(String url, bool legacy, {int offset = 0}) async {
    loads.add(VideoSourceResolveRequest(
        episodeUrl: url, useLegacyParser: legacy, offset: offset));
    final changed = _loaded;
    _loaded = Completer<void>();
    changed.complete();
    await loading?.future;
  }

  Future<void> waitForLoads(int count) async {
    while (loads.length < count) {
      await _loaded.future.timeout(const Duration(seconds: 2));
    }
  }

  void source(String url, [int offset = 0]) =>
      videoParserEventController.add((url, offset));
  @override
  Future<void> unloadPage() async {
    unloads++;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    disposeEventControllers();
  }
}

void main() {
  test(
      'success preserves parser parameters, unloads pages and reuses the controller',
      () async {
    final controller = Controller();
    final service =
        WebViewVideoSourceService(controllerFactory: () => controller);
    addTearDown(service.dispose);
    final first = service.resolve(const VideoSourceResolveRequest(
        episodeUrl: 'first', useLegacyParser: true, offset: 42));
    await controller.waitForLoads(1);
    expect(controller.loads.single.useLegacyParser, isTrue);
    expect(controller.loads.single.offset, 42);
    final cancelled = VideoSourceCancellation()..cancel();
    await expectLater(
        service.resolve(VideoSourceResolveRequest(
            episodeUrl: 'already-cancelled', cancellation: cancelled)),
        throwsA(isA<VideoSourceCancelledException>()));
    controller.source('first.m3u8', 42);
    expect((await first).offset, 42);
    final second =
        service.resolve(const VideoSourceResolveRequest(episodeUrl: 'second'));
    await controller.waitForLoads(2);
    controller.source('second.mp4');
    expect((await second).url, 'second.mp4');
    expect(controller.unloads, 2);
    await service.dispose();
    await service.dispose();
    expect(controller.disposals, 1);
    await expectLater(
        service.resolve(
            const VideoSourceResolveRequest(episodeUrl: 'after-dispose')),
        throwsA(isA<VideoSourceCancelledException>()));
  });

  test(
      'cancellation completes during native initialization; disposal drains initialization before release',
      () async {
    final controller = Controller()..initialization = Completer<void>();
    final service =
        WebViewVideoSourceService(controllerFactory: () => controller);
    final cancellation = VideoSourceCancellation();
    final pending = service.resolve(VideoSourceResolveRequest(
        episodeUrl: 'first', cancellation: cancellation));
    final rejected =
        expectLater(pending, throwsA(isA<VideoSourceCancelledException>()));
    await controller.initialized.future;
    cancellation.cancel();
    await rejected;
    var disposed = false;
    final disposal = service.dispose().then((_) => disposed = true);
    await Future<void>.delayed(Duration.zero);
    expect(disposed, isFalse);
    expect(controller.disposals, 0);
    controller.initialization!.complete();
    await disposal;
    expect(controller.loads, isEmpty);
    expect(controller.disposals, 1);
  });

  test('newest request supersedes both active and queued playback requests',
      () async {
    final old = Controller()..initialization = Completer<void>();
    final current = Controller();
    final controllers = [old, current];
    final service = WebViewVideoSourceService(
        controllerFactory: () => controllers.removeAt(0));
    addTearDown(service.dispose);
    final first =
        service.resolve(const VideoSourceResolveRequest(episodeUrl: 'first'));
    final firstCheck =
        expectLater(first, throwsA(isA<VideoSourceCancelledException>()));
    await old.initialized.future;
    final second =
        service.resolve(const VideoSourceResolveRequest(episodeUrl: 'second'));
    final secondCheck =
        expectLater(second, throwsA(isA<VideoSourceCancelledException>()));
    final third =
        service.resolve(const VideoSourceResolveRequest(episodeUrl: 'third'));
    await Future.wait([firstCheck, secondCheck]);
    await current.waitForLoads(1);
    expect(current.loads.single.episodeUrl, 'third');
    current.source('third.mp4');
    expect((await third).url, 'third.mp4');
    old.initialization!.complete();
  });

  test(
      'load timeout retires the controller and ignores late events from its page',
      () async {
    final old = Controller()..loading = Completer<void>();
    final current = Controller();
    final controllers = [old, current];
    final service = WebViewVideoSourceService(
        controllerFactory: () => controllers.removeAt(0));
    addTearDown(service.dispose);
    final first = service.resolve(const VideoSourceResolveRequest(
        episodeUrl: 'first', timeout: Duration.zero));
    final rejected =
        expectLater(first, throwsA(isA<VideoSourceTimeoutException>()));
    await old.waitForLoads(1);
    await rejected;
    final next =
        service.resolve(const VideoSourceResolveRequest(episodeUrl: 'next'));
    await current.waitForLoads(1);
    old.source('stale.m3u8');
    current.source('current.mp4');
    expect((await next).url, 'current.mp4');
    old.loading!.complete();
    await service.dispose();
    expect(old.disposals, 1);
    expect(current.disposals, 1);
  });

  test(
      'parser errors during a pending load reach the caller without unhandled stream failures',
      () async {
    final controller = Controller()..loading = Completer<void>();
    final service =
        WebViewVideoSourceService(controllerFactory: () => controller);
    addTearDown(service.dispose);
    final pending =
        service.resolve(const VideoSourceResolveRequest(episodeUrl: 'first'));
    final rejected = expectLater(pending, throwsFormatException);
    await controller.waitForLoads(1);
    controller.videoParserEventController
        .addError(const FormatException('bad source'));
    await rejected;
    controller.loading!.complete();
    await service.dispose();
    expect(controller.disposals, 1);
  });

  test('failed initialization is disposed and the next request can recover',
      () async {
    final old = Controller()..initialization = Completer<void>();
    final current = Controller();
    final controllers = [old, current];
    final service = WebViewVideoSourceService(
        controllerFactory: () => controllers.removeAt(0));
    addTearDown(service.dispose);
    final pending =
        service.resolve(const VideoSourceResolveRequest(episodeUrl: 'first'));
    final rejected = expectLater(pending, throwsStateError);
    await old.initialized.future;
    old.initialization!.completeError(StateError('native startup failed'));
    await rejected;
    final next =
        service.resolve(const VideoSourceResolveRequest(episodeUrl: 'next'));
    await current.waitForLoads(1);
    current.source('current.mp4');
    await next;
    await service.dispose();
    expect(old.disposals, 1);
  });
}

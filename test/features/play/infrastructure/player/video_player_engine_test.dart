import 'dart:async';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'package:anime_flow/features/play/infrastructure/player/video_player/video_player_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late VideoPlayerPlatform previousPlatform;
  late _FakeVideoPlatform platform;
  late VideoPlayerEngine engine;
  final source =
      PlaybackSource.network(uri: Uri.parse('https://example.com/video.mp4'));

  Future<void> openSource() async {
    await engine.createPlayer(source);
    await engine.open();
  }

  setUp(() async {
    previousPlatform = VideoPlayerPlatform.instance;
    platform = _FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    engine = VideoPlayerEngine();
    await engine.initialize();
  });
  tearDown(() async {
    await engine.dispose();
    VideoPlayerPlatform.instance = previousPlatform;
    debugDefaultTargetPlatformOverride = null;
  });

  test('Android opts in before prepare and switches efficiency on and off',
      () async {
    await openSource();
    expect(platform.created.single.videoPlayerOptions?.videoEffects?.effect,
        VideoEffectType.none);
    await engine.setUpscalePreset(UpscalePreset.efficiency);
    expect(platform.effects.last, VideoEffectType.shaderBundle);
    await engine.setUpscalePreset(UpscalePreset.off);
    expect(platform.effects.last, VideoEffectType.none);
  });

  test('preset selected before opening survives controller replacement',
      () async {
    await engine.setUpscalePreset(UpscalePreset.efficiency);
    await openSource();
    await openSource();
    expect(
        platform.created.map((c) => c.videoPlayerOptions?.videoEffects?.effect),
        everyElement(VideoEffectType.shaderBundle));
    expect(platform.disposed, [1]);
  });

  test('stop releases the controller before a replacement is opened', () async {
    await openSource();
    await engine.stop();
    await engine.stop();
    await engine.setVolume(42);
    await engine.setRate(1.25);
    expect(platform.disposed, [1]);
    expect(platform.created, hasLength(1));

    await expectLater(engine.open(), throwsStateError);
    expect(platform.created, hasLength(1));
    await engine.createPlayer(source);
    expect(platform.created, hasLength(2));
    await engine.open(autoPlay: true);
    expect(platform.created, hasLength(2));
    expect(platform.volumes.last, (2, 0.42));
    expect(platform.rates.last, (2, 1.25));
  });

  test(
      'rejected update does not persist the failed preset into the next episode',
      () async {
    await openSource();
    platform.rejectEffect = true;
    await expectLater(
        engine.setUpscalePreset(UpscalePreset.efficiency), throwsStateError);
    await openSource();
    expect(platform.created.last.videoPlayerOptions?.videoEffects?.effect,
        VideoEffectType.none);
  });

  test('quality is unavailable and cannot change an active efficiency preset',
      () async {
    await engine.setUpscalePreset(UpscalePreset.efficiency);
    expect(engine.capabilities.supportsUpscalePreset(UpscalePreset.quality),
        isFalse);
    await expectLater(
        engine.setUpscalePreset(UpscalePreset.quality), throwsUnsupportedError);
    await openSource();
    expect(platform.created.single.videoPlayerOptions?.videoEffects?.effect,
        VideoEffectType.shaderBundle);
  });

  test('iOS opts in and supplies Metal shaders across player replacement',
      () async {
    await engine.dispose();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    engine = VideoPlayerEngine();
    await engine.initialize();
    expect(engine.capabilities.supportsUpscalePreset(UpscalePreset.efficiency),
        isTrue);
    await engine.setUpscalePreset(UpscalePreset.efficiency);
    await openSource();
    await openSource();
    for (final creation in platform.created) {
      final effect = creation.videoPlayerOptions!.videoEffects!;
      expect(effect.effect, VideoEffectType.shaderBundle);
      expect(effect.shaderBundle!.encoded, contains('videoFragment'));
      expect(effect.shaderBundle!.encoded, isNot(contains('#version 300 es')));
    }
    await engine.setUpscalePreset(UpscalePreset.off);
    expect(platform.effects.last, VideoEffectType.none);
  });

  test('macOS retains normal playback without exposing native effects',
      () async {
    await engine.dispose();
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    engine = VideoPlayerEngine();
    await engine.initialize();
    expect(engine.capabilities.supportsUpscalePreset(UpscalePreset.efficiency),
        isFalse);
    await openSource();
    expect(platform.created.single.videoPlayerOptions?.videoEffects, isNull);
    await expectLater(engine.setUpscalePreset(UpscalePreset.efficiency),
        throwsUnsupportedError);
  });

  testWidgets(
      'physical fitted output survives toggles and follows layout changes',
      (tester) async {
    await openSource();
    Widget view(double width) => MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 3),
          child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                  child: SizedBox(
                      width: width,
                      height: 300,
                      child: engine.buildVideoSurface(fit: BoxFit.contain)))),
        );
    await tester.pumpWidget(view(320));
    await tester.pump();
    expect(platform.configurations.last.outputWidth, 960);
    expect(platform.configurations.last.outputHeight, 540);
    await tester
        .runAsync(() => engine.setUpscalePreset(UpscalePreset.efficiency));
    expect(platform.configurations.last.effect, VideoEffectType.shaderBundle);
    expect(platform.configurations.last.shaderBundle, isNotNull);
    expect(platform.configurations.last.outputWidth, 960);
    expect(platform.configurations.last.outputHeight, 540);
    await tester.runAsync(() => engine.setUpscalePreset(UpscalePreset.off));
    expect(platform.configurations.last.outputWidth, 960);
    await tester.pumpWidget(view(400));
    // The layout update queues behind the preset changes run outside fake async.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(platform.configurations.last.outputWidth, 1200);
    expect(platform.configurations.last.outputHeight, 675);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(engine.dispose);
    debugDefaultTargetPlatformOverride = null;
  });
}

class _FakeVideoPlatform extends VideoPlayerPlatform {
  final created = <VideoCreationOptions>[];
  final effects = <VideoEffectType>[];
  final configurations = <VideoEffectConfiguration>[];
  final disposed = <int>[];
  final volumes = <(int, double)>[];
  final rates = <(int, double)>[];
  bool rejectEffect = false;

  @override
  Future<void> init() async {}
  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    created.add(options);
    return created.length;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(minutes: 1),
        size: const Size(640, 360),
      ));
  @override
  Future<void> setVideoEffectConfiguration(
      int playerId, VideoEffectConfiguration configuration) async {
    if (rejectEffect) throw StateError('effect rejected');
    effects.add(configuration.effect);
    configurations.add(configuration);
  }

  @override
  Widget buildView(int playerId) => const SizedBox.expand();

  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {
    volumes.add((playerId, volume));
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    rates.add((playerId, speed));
  }

  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
}

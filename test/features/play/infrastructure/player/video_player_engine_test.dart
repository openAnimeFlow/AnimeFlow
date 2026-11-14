import 'dart:async';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'package:anime_flow/features/play/infrastructure/player/video_player/video_player_engine.dart';
import 'package:anime_flow/features/play/infrastructure/player/video_player/android_upscale_shaders.dart';
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
      PlaybackSource(uri: Uri.parse('https://example.com/video.mp4'));

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
    await engine.open(source);
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
    await engine.open(source);
    await engine.open(source);
    expect(
        platform.created.map((c) => c.videoPlayerOptions?.videoEffects?.effect),
        everyElement(VideoEffectType.shaderBundle));
    expect(platform.disposed, [1]);
  });

  test(
      'rejected update does not persist the failed preset into the next episode',
      () async {
    await engine.open(source);
    platform.rejectEffect = true;
    await expectLater(
        engine.setUpscalePreset(UpscalePreset.efficiency), throwsStateError);
    await engine.open(source);
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
    await engine.open(source);
    expect(platform.created.single.videoPlayerOptions?.videoEffects?.effect,
        VideoEffectType.shaderBundle);
  });

  test('iOS retains normal playback and does not expose Android effects',
      () async {
    await engine.dispose();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    engine = VideoPlayerEngine();
    await engine.initialize();
    expect(engine.capabilities.supportsUpscaling, isFalse);
    await engine.setUpscalePreset(UpscalePreset.off);
    await engine.open(source);
    expect(platform.created.single.videoPlayerOptions?.videoEffects, isNull);
    await expectLater(engine.setUpscalePreset(UpscalePreset.efficiency),
        throwsUnsupportedError);
    expect(platform.effects, isEmpty);
  });

  testWidgets(
      'physical fitted output survives toggles and follows layout changes',
      (tester) async {
    await tester.runAsync(AndroidUpscaleShaders.loadEfficiency);
    await engine.open(source);
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
    await engine.setUpscalePreset(UpscalePreset.efficiency);
    expect(platform.configurations.last.effect, VideoEffectType.shaderBundle);
    expect(platform.configurations.last.shaderBundle, isNotNull);
    expect(platform.configurations.last.outputWidth, 960);
    expect(platform.configurations.last.outputHeight, 540);
    await engine.setUpscalePreset(UpscalePreset.off);
    expect(platform.configurations.last.outputWidth, 960);
    await tester.pumpWidget(view(400));
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
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> pause(int playerId) async {}
}

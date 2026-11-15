import 'dart:async';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/video_validation_exception.dart';
import 'package:anime_flow/features/play/infrastructure/player/video_player/video_player_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late VideoPlayerPlatform previousPlatform;
  late _FakeVideoPlatform platform;
  late VideoPlayerEngine engine;
  setUp(() async {
    previousPlatform = VideoPlayerPlatform.instance;
    platform = _FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    engine = VideoPlayerEngine();
    await engine.initialize();
  });
  tearDown(() async {
    await engine.dispose();
    VideoPlayerPlatform.instance = previousPlatform;
  });

  test('manual local video is validated by initialization, not extension',
      () async {
    await engine.open(PlaybackSource.localFile(
        Uri.file('C:/video/renamed.data', windows: true).toString()));
    expect(platform.created, hasLength(1));
    expect(platform.disposed, isEmpty);
  });

  test('localFile rejects audio-only without an optional validation flag',
      () async {
    platform.videoSize = Size.zero;
    await expectLater(
      engine.open(PlaybackSource.localFile(
          Uri.file('C:/video/audio.mp4', windows: true).toString())),
      throwsA(isA<VideoValidationException>()),
    );
    expect(platform.disposed, [1]);
  });

  test('native format failure propagates and releases the controller',
      () async {
    platform.initializationError = PlatformException(
        code: 'unsupported_codec', message: 'Unsupported video codec');
    await expectLater(
      engine.open(PlaybackSource.localFile(
          Uri.file('C:/video/unsupported.mp4', windows: true).toString())),
      throwsA(isA<PlatformException>()),
    );
    expect(platform.disposed, [1]);
  });
}

class _FakeVideoPlatform extends VideoPlayerPlatform {
  final created = <VideoCreationOptions>[];
  final disposed = <int>[];
  Size videoSize = const Size(640, 360);
  Object? initializationError;

  @override
  Future<void> init() async {}
  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    created.add(options);
    return created.length;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => initializationError != null
      ? Stream.error(initializationError!)
      : Stream.value(VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(minutes: 1),
          size: videoSize,
        ));
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

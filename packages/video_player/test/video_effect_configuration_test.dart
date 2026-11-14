import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'video_player_test.dart' show FakeVideoPlayerPlatform;

class _Platform extends FakeVideoPlayerPlatform {
  final effects = <int, VideoEffectConfiguration>{};
  bool failCreate = false;

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    if (failCreate) throw StateError('native effect initialization failed');
    return super.createWithOptions(options);
  }

  @override
  Future<void> setVideoEffectConfiguration(
    int playerId,
    VideoEffectConfiguration configuration,
  ) async {
    effects[playerId] = configuration;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Platform platform;
  const off = VideoEffectConfiguration();
  const gray = VideoEffectConfiguration(effect: VideoEffectType.debugGrayscale);

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    VideoPlayerPlatform.instance = platform = _Platform();
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  VideoPlayerController controller({VideoEffectConfiguration? initial = off}) =>
      VideoPlayerController.networkUrl(
        Uri.parse('https://example.com/video.mp4'),
        videoPlayerOptions: VideoPlayerOptions(videoEffects: initial),
      );

  test(
    'initial configuration is passed during create and updates stay per controller',
    () async {
      final first = controller(initial: gray);
      final second = controller();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await first.initialize();
      await second.initialize();
      expect(
        platform.videoPlayerOptions.map((options) => options!.videoEffects),
        [gray, off],
      );
      await first.setVideoEffectConfiguration(off);
      await second.setVideoEffectConfiguration(gray);
      expect(platform.effects, {first.playerId: off, second.playerId: gray});
    },
  );

  test(
    'rejects updates before initialization, without opt-in and after disposal',
    () async {
      final optedIn = controller();
      await expectLater(
        optedIn.setVideoEffectConfiguration(gray),
        throwsStateError,
      );
      await optedIn.initialize();
      await optedIn.dispose();
      await expectLater(
        optedIn.setVideoEffectConfiguration(gray),
        throwsStateError,
      );
      final ordinary = controller(initial: null);
      await ordinary.initialize();
      await expectLater(
        ordinary.setVideoEffectConfiguration(gray),
        throwsStateError,
      );
      await ordinary.dispose();
      expect(platform.effects, isEmpty);
    },
  );

  test('native creation failure still allows disposal to finish', () async {
    platform.failCreate = true;
    final player = controller();
    await expectLater(player.initialize(), throwsStateError);
    await player.dispose().timeout(const Duration(seconds: 1));
    expect(platform.calls, isNot(contains('dispose')));
  });

  test(
    'unsupported platforms reject opt-in before allocating a player',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final player = controller(initial: gray);
      await expectLater(player.initialize(), throwsUnsupportedError);
      await player.dispose();
      expect(platform.videoPlayerOptions, isEmpty);
    },
  );

  test(
    'iOS passes initial configuration and permits runtime effects',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final player = controller();
      addTearDown(player.dispose);
      await player.initialize();
      await player.setVideoEffectConfiguration(gray);
      expect(platform.videoPlayerOptions.single!.videoEffects, off);
      expect(platform.effects[player.playerId], gray);
    },
  );
}

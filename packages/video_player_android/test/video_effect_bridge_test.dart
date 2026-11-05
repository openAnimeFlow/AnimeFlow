import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:video_player_android/src/messages.g.dart';
import 'package:video_player_android/video_player_android.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'android_video_player_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const gray = VideoEffectConfiguration(effect: VideoEffectType.debugGrayscale);

  test(
    'creation and runtime effects target the correct native player',
    () async {
      final plugin = MockAndroidVideoPlayerApi();
      final apis = {
        1: MockVideoPlayerInstanceApi(),
        2: MockVideoPlayerInstanceApi(),
      };
      final streams = {
        1: StreamController<PlatformVideoEvent>(),
        2: StreamController<PlatformVideoEvent>(),
      };
      var id = 0;
      when(plugin.createForTextureView(any)).thenAnswer((_) async {
        id++;
        return TexturePlayerIds(playerId: id, textureId: 100 + id);
      });
      final player = AndroidVideoPlayer(
        pluginApi: plugin,
        playerApiProvider: (id) => apis[id]!,
        videoEventStreamProvider: (id) => streams[int.parse(id)]!.stream,
      );
      for (final initial in [gray, const VideoEffectConfiguration()]) {
        await player.createWithOptions(
          VideoCreationOptions(
            dataSource: DataSource(
              sourceType: DataSourceType.network,
              uri: 'https://example.com/v.mp4',
            ),
            viewType: VideoViewType.textureView,
            videoPlayerOptions: VideoPlayerOptions(videoEffects: initial),
          ),
        );
      }
      final creations = verify(
        plugin.createForTextureView(captureAny),
      ).captured.cast<CreationOptions>();
      expect(creations.map((c) => c.videoEffect), [
        PlatformVideoEffect.debugGrayscale,
        PlatformVideoEffect.none,
      ]);
      await player.setVideoEffectConfiguration(2, gray);
      verify(
        apis[2]!.setVideoEffect(PlatformVideoEffect.debugGrayscale, null, null),
      ).called(1);
      verifyNever(apis[1]!.setVideoEffect(any, any, any));
      await player.dispose(1);
      await player.dispose(2);
      for (final stream in streams.values) {
        await stream.close();
      }
    },
  );

  test('platform view opt-in is rejected without native allocation', () async {
    final plugin = MockAndroidVideoPlayerApi();
    final player = AndroidVideoPlayer(pluginApi: plugin);
    await expectLater(
      player.createWithOptions(
        VideoCreationOptions(
          dataSource: DataSource(
            sourceType: DataSourceType.network,
            uri: 'https://example.com/v.mp4',
          ),
          viewType: VideoViewType.platformView,
          videoPlayerOptions: VideoPlayerOptions(videoEffects: gray),
        ),
      ),
      throwsUnsupportedError,
    );
    verifyNever(plugin.createForPlatformView(any));
    verifyNever(plugin.createForTextureView(any));
  });
}

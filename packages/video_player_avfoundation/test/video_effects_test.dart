import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_avfoundation/src/video_player_plugin_messages.g.dart';
import 'package:video_player_avfoundation/video_player_avfoundation.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final apiPrefix =
      'dev.flutter.pigeon.video_player_avfoundation.AVFoundationVideoPlayerApi';
  late AVFoundationVideoPlayer player;
  late List<CreationOptions> creations;
  late List<List<Object?>> updates;
  late bool rejectUpdate;
  BasicMessageChannel<Object?> channel(String method) => BasicMessageChannel(
    '$apiPrefix.$method',
    AVFoundationVideoPlayerApi.pigeonChannelCodec,
  );
  VideoCreationOptions options(
    VideoEffectConfiguration? effects, {
    VideoViewType view = VideoViewType.textureView,
  }) => VideoCreationOptions(
    dataSource: DataSource(
      sourceType: DataSourceType.network,
      uri: 'https://example.com/test.mp4',
    ),
    viewType: view,
    videoPlayerOptions: VideoPlayerOptions(videoEffects: effects),
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    player = AVFoundationVideoPlayer();
    creations = [];
    updates = [];
    rejectUpdate = false;
    binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
      channel('createForTextureView'),
      (message) async {
        creations.add((message! as List).single as CreationOptions);
        return [
          TexturePlayerIds(
            playerId: creations.length,
            textureId: 100 + creations.length,
          ),
        ];
      },
    );
    binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
      channel('setVideoEffectConfiguration'),
      (message) async {
        updates.add((message! as List).cast<Object?>());
        return rejectUpdate ? ['video_shader', 'Invalid shader', null] : [null];
      },
    );
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
      channel('createForTextureView'),
      null,
    );
    binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
      channel('setVideoEffectConfiguration'),
      null,
    );
  });

  test(
    'initial effect travels with creation and runtime update targets the player',
    () async {
      final bundle = VideoShaderBundle(
        manifest: '[{"asset":"copy.metal"}]',
        shaders: {'copy.metal': 'fragment source'},
      );
      final config = VideoEffectConfiguration(
        effect: VideoEffectType.shaderBundle,
        shaderBundle: bundle,
        outputWidth: 1920,
        outputHeight: 1080,
      );
      final id = (await player.createWithOptions(options(config)))!;
      final encoded = jsonDecode(creations.single.videoEffects!) as Map;
      expect(encoded, {
        'effect': 'shaderBundle',
        'shaderBundle': bundle.encoded,
        'outputWidth': 1920,
        'outputHeight': 1080,
      });
      expect(updates, isEmpty);
      await player.setVideoEffectConfiguration(
        id,
        const VideoEffectConfiguration(effect: VideoEffectType.debugGrayscale),
      );
      expect(updates.single.first, id);
      expect(
        jsonDecode(updates.single.last! as String)['effect'],
        'debugGrayscale',
      );
    },
  );

  test('no opt-in keeps the upstream creation path', () async {
    await player.createWithOptions(options(null));
    expect(creations.single.videoEffects, isNull);
  });

  test(
    'platform views and macOS reject opt-in before creating a native player',
    () async {
      await expectLater(
        player.createWithOptions(
          options(
            const VideoEffectConfiguration(),
            view: VideoViewType.platformView,
          ),
        ),
        throwsUnsupportedError,
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await expectLater(
        player.createWithOptions(options(const VideoEffectConfiguration())),
        throwsUnsupportedError,
      );
      expect(creations, isEmpty);
    },
  );

  test(
    'native errors propagate and unknown players cannot receive updates',
    () async {
      final id = (await player.createWithOptions(
        options(const VideoEffectConfiguration()),
      ))!;
      rejectUpdate = true;
      await expectLater(
        player.setVideoEffectConfiguration(
          id,
          const VideoEffectConfiguration(),
        ),
        throwsA(isA<PlatformException>()),
      );
      expect(
        () => player.setVideoEffectConfiguration(
          99,
          const VideoEffectConfiguration(),
        ),
        throwsStateError,
      );
      expect(updates, hasLength(1));
    },
  );

  test(
    'oversized output is rejected before crossing the native bridge',
    () async {
      await expectLater(
        player.createWithOptions(
          options(
            const VideoEffectConfiguration(
              outputWidth: 0x80000000,
              outputHeight: 2,
            ),
          ),
        ),
        throwsArgumentError,
      );
      expect(creations, isEmpty);
    },
  );
}

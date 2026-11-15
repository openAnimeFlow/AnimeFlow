import 'dart:convert';

import 'package:anime_flow/features/play/infrastructure/player/video_player/video_player_upscale_shaders.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test(
        '$platform loads and shares a complete efficiency bundle after a failure',
        () async {
      debugDefaultTargetPlatformOverride = platform;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (_) async => null);
      try {
        await expectLater(VideoPlayerUpscaleShaders.loadEfficiency(),
            throwsA(isA<FlutterError>()));
      } finally {
        messenger.setMockMessageHandler('flutter/assets', null);
      }

      final loading = VideoPlayerUpscaleShaders.loadEfficiency();
      expect(VideoPlayerUpscaleShaders.loadEfficiency(), same(loading));
      final bundle = await loading;
      final json = jsonDecode(bundle.encoded) as Map<String, dynamic>;
      final passes = json['passes'] as List<dynamic>;
      final sources = json['shaders'] as Map<String, dynamic>;
      expect(json['version'], 1);
      expect(passes, hasLength(31));
      for (final pass in passes) {
        expect(
            sources[pass['asset']],
            platform == TargetPlatform.android
                ? startsWith('#version 300 es')
                : contains('fragment float4 videoFragment('));
      }
      expect(await VideoPlayerUpscaleShaders.loadEfficiency(), same(bundle));
    });
  }
}

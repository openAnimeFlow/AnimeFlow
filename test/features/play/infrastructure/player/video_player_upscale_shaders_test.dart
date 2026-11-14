import 'dart:convert';

import 'package:anime_flow/features/play/infrastructure/player/video_player/video_player_upscale_shaders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test('$platform assets form a complete reusable efficiency bundle',
        () async {
      debugDefaultTargetPlatformOverride = platform;
      final bundle = await VideoPlayerUpscaleShaders.loadEfficiency();
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

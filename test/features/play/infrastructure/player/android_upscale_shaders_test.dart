import 'dart:convert';

import 'package:anime_flow/features/play/infrastructure/player/video_player/android_upscale_shaders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('application assets form a complete reusable efficiency bundle', () async {
    final bundle = await AndroidUpscaleShaders.loadEfficiency();
    final json = jsonDecode(bundle.encoded) as Map<String, dynamic>;
    final passes = json['passes'] as List<dynamic>;
    final sources = json['shaders'] as Map<String, dynamic>;
    expect(json['version'], 1);
    expect(passes, hasLength(31));
    for (final pass in passes) {
      expect(sources[pass['asset']], startsWith('#version 300 es'));
    }
    expect(await AndroidUpscaleShaders.loadEfficiency(), same(bundle));
  });
}

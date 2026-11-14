import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  const manifest = '[{"asset":"pass.glsl"}]';
  test(
    'bundle captures sources and includes content in configuration equality',
    () {
      final sources = {'pass.glsl': 'first'};
      final first = VideoShaderBundle(manifest: manifest, shaders: sources);
      sources['pass.glsl'] = 'second';
      final second = VideoShaderBundle(manifest: manifest, shaders: sources);
      expect((jsonDecode(first.encoded) as Map)['shaders'], {
        'pass.glsl': 'first',
      });
      expect(
        VideoEffectConfiguration(
          effect: VideoEffectType.shaderBundle,
          shaderBundle: first,
        ),
        isNot(
          VideoEffectConfiguration(
            effect: VideoEffectType.shaderBundle,
            shaderBundle: second,
          ),
        ),
      );
    },
  );
  test(
    'missing or blank shader sources and empty manifests fail before bridge',
    () {
      expect(
        () => VideoShaderBundle(manifest: manifest, shaders: {}),
        throwsArgumentError,
      );
      expect(
        () =>
            VideoShaderBundle(manifest: manifest, shaders: {'pass.glsl': ' '}),
        throwsArgumentError,
      );
      expect(
        () => VideoShaderBundle(manifest: '[]', shaders: {}),
        throwsArgumentError,
      );
    },
  );
}

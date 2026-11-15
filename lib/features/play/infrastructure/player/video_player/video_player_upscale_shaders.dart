import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Application-owned presets, loaded lazily in the native backend's shader language.
class VideoPlayerUpscaleShaders {
  static final _efficiency = <TargetPlatform, Future<VideoShaderBundle>>{};

  static Future<VideoShaderBundle> loadEfficiency() {
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      return Future.error(
        UnsupportedError('Video shader bundles require Android or iOS'),
      );
    }
    return _efficiency.putIfAbsent(platform, () async {
      try {
        return await _load(platform);
      } catch (_) {
        _efficiency.remove(platform);
        rethrow;
      }
    });
  }

  static Future<VideoShaderBundle> _load(TargetPlatform platform) async {
    final directory =
        'assets/shaders/video_player/${platform == TargetPlatform.iOS ? 'ios' : 'android'}';
    final manifest =
        await rootBundle.loadString('$directory/efficiency.json', cache: false);
    final passes = jsonDecode(manifest) as List<dynamic>;
    final names =
        passes.map((pass) => (pass as Map)['asset'] as String).toSet();
    final shaders = <String, String>{};
    for (final name in names) {
      shaders[name] =
          await rootBundle.loadString('$directory/$name', cache: false);
    }
    return VideoShaderBundle(manifest: manifest, shaders: shaders);
  }
}

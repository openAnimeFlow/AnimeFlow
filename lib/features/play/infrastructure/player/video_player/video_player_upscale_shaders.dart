import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Application-owned presets, loaded lazily in the native backend's shader language.
class VideoPlayerUpscaleShaders {
  static final _efficiency = <TargetPlatform, VideoShaderBundle>{};
  static final _loading = <TargetPlatform, Future<VideoShaderBundle>>{};

  static Future<VideoShaderBundle> loadEfficiency() async {
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      throw UnsupportedError('Video shader bundles require Android or iOS');
    }
    if (_efficiency[platform] case final cached?) return cached;
    try {
      return _efficiency[platform] =
          await _loading.putIfAbsent(platform, () => _load(platform));
    } finally {
      _loading.remove(platform);
    }
  }

  static Future<VideoShaderBundle> _load(TargetPlatform platform) async {
    final directory =
        'assets/shaders/video_player/${platform == TargetPlatform.iOS ? 'ios' : 'android'}';
    final manifest = await rootBundle.loadString('$directory/efficiency.json');
    final passes = jsonDecode(manifest) as List<dynamic>;
    final names =
        passes.map((pass) => (pass as Map)['asset'] as String).toSet();
    final shaders = <String, String>{};
    for (final name in names) {
      shaders[name] = await rootBundle.loadString('$directory/$name');
    }
    return VideoShaderBundle(manifest: manifest, shaders: shaders);
  }
}

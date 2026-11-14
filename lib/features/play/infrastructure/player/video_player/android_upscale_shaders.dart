import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Application-owned Anime4K preset, converted to the Android bundle contract.
class AndroidUpscaleShaders {
  static VideoShaderBundle? _efficiency;

  static Future<VideoShaderBundle> loadEfficiency() async {
    if (_efficiency case final cached?) return cached;
    const directory = 'assets/shaders/android';
    final manifest = await rootBundle.loadString('$directory/efficiency.json');
    final passes = jsonDecode(manifest) as List<dynamic>;
    final names =
        passes.map((pass) => (pass as Map)['asset'] as String).toSet();
    final shaders = <String, String>{};
    for (final name in names) {
      shaders[name] = await rootBundle.loadString('$directory/$name');
    }
    return _efficiency =
        VideoShaderBundle(manifest: manifest, shaders: shaders);
  }
}

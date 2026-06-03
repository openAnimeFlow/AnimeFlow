import 'dart:io';

import 'package:anime_flow/utils/logger.dart';
import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shaders_controller.g.dart';

@Riverpod(keepAlive: true)
Future<Directory> shadersDirectory(Ref ref) async {
  final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final assets = assetManifest.listAssets();
  final directory = await getApplicationSupportDirectory();
  final shadersDirectory = Directory(path.join(directory.path, 'anime_shaders'));

  if (!await shadersDirectory.exists()) {
    await shadersDirectory.create(recursive: true);
    LiggLogger().i('ShaderManager: Create GLSL Shader: ${shadersDirectory.path}');
  }

  final shaderFiles = assets.where((String asset) =>
      asset.startsWith('assets/shaders/') && asset.endsWith('.glsl'));

  int copiedFilesCount = 0;

  for (var filePath in shaderFiles) {
    final fileName = filePath.split('/').last;
    final targetFile = File(path.join(shadersDirectory.path, fileName));
    if (await targetFile.exists()) {
      LiggLogger()
          .i('ShaderManager: GLSL Shader exists, skip: ${targetFile.path}');
      continue;
    }

    try {
      final data = await rootBundle.load(filePath);
      final List<int> bytes = data.buffer.asUint8List();
      await targetFile.writeAsBytes(bytes);
      copiedFilesCount++;
      LiggLogger().i('ShaderManager: Copy: ${targetFile.path}');
    } catch (e) {
      LiggLogger().e('ShaderManager: Copy: ($filePath)', error: e);
    }
  }

  LiggLogger().i('ShaderManager: $copiedFilesCount GLSL files copied to ${shadersDirectory.path}');
  return shadersDirectory;
}

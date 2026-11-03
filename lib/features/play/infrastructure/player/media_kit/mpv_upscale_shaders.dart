import 'dart:io';

import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'package:path/path.dart' as path;

/// MPV 的 Anime4K 资源与路径编码。
class MpvUpscaleShaders {
  const MpvUpscaleShaders(this.loadDirectory);

  final Future<Directory> Function() loadDirectory;

  Future<String> resolve(UpscalePreset preset) async {
    final shaders = switch (preset) {
      UpscalePreset.off => const <String>[],
      UpscalePreset.efficiency => _efficiencyShaders,
      UpscalePreset.quality => _qualityShaders,
    };
    if (shaders.isEmpty) return '';
    final directory = await loadDirectory();
    return shaders
        .map((shader) => path.join(directory.path, shader))
        .join(Platform.isWindows ? ';' : ':');
  }
}

/// 超分辨率滤镜
const List<String> _qualityShaders = [
  'Anime4K_Clamp_Highlights.glsl',
  'Anime4K_Restore_CNN_VL.glsl',
  'Anime4K_Upscale_CNN_x2_VL.glsl',
  'Anime4K_AutoDownscalePre_x2.glsl',
  'Anime4K_AutoDownscalePre_x4.glsl',
  'Anime4K_Upscale_CNN_x2_M.glsl'
];

/// 超分辨率滤镜 (轻量)
const List<String> _efficiencyShaders = [
  'Anime4K_Clamp_Highlights.glsl',
  'Anime4K_Restore_CNN_M.glsl',
  'Anime4K_Restore_CNN_S.glsl',
  'Anime4K_Upscale_CNN_x2_M.glsl',
  'Anime4K_AutoDownscalePre_x2.glsl',
  'Anime4K_AutoDownscalePre_x4.glsl',
  'Anime4K_Upscale_CNN_x2_S.glsl'
];

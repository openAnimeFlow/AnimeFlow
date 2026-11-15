import 'upscale_preset.dart';

class PlayerCapabilities {
  final bool supportsScreenshot;
  final bool supportsExternalSubtitle;

  /// 可启用的超分档位；off 始终可用，无需在此列出。
  final Set<UpscalePreset> supportedUpscalePresets;
  final bool supportsHardwareDecoder;

  const PlayerCapabilities({
    this.supportsScreenshot = false,
    this.supportsExternalSubtitle = false,
    this.supportedUpscalePresets = const {},
    this.supportsHardwareDecoder = false,
  });

  bool supportsUpscalePreset(UpscalePreset preset) =>
      preset == UpscalePreset.off || supportedUpscalePresets.contains(preset);
}

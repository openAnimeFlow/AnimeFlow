class PlayerCapabilities {
  final bool supportsScreenshot;
  final bool supportsExternalSubtitle;
  final bool supportsShader;
  final bool supportsHardwareDecoder;
  final bool supportsAudioOnly;

  const PlayerCapabilities({
    this.supportsScreenshot = false,
    this.supportsExternalSubtitle = false,
    this.supportsShader = false,
    this.supportsHardwareDecoder = false,
    this.supportsAudioOnly = false,
  });
}

/// 与播放器内核无关的超分档位；具体算法、资源和 GPU 管线由内核实现。
enum UpscalePreset {
  off,
  efficiency,
  quality;

  bool get isEnabled => this != off;
}

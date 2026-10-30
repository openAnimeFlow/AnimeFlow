import 'package:flutter/foundation.dart';

enum PlayerKernel {
  mediaKit,
  fvp,
  videoPlayer;

  bool get isSupported =>
      this != videoPlayer ||
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS));

  static List<PlayerKernel> get available =>
      values.where((kernel) => kernel.isSupported).toList();
}

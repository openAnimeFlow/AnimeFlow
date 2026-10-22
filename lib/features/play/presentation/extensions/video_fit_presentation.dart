import 'package:anime_flow/features/play/domain/player/video_fit.dart';
import 'package:material_ui/material_ui.dart';

extension VideoFitPresentation on VideoFit {
  BoxFit get boxFit => switch (this) {
        VideoFit.contain => BoxFit.contain,
        VideoFit.cover => BoxFit.cover,
        VideoFit.fill => BoxFit.fill,
      };
}

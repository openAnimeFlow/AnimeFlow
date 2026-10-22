import 'package:material_ui/material_ui.dart';

/// Rendering adapter, consumed only by the presentation layer.
/// Playback control remains on the independent PlayerEngine contract.
abstract interface class PlayerVideoSurface {
  Widget buildVideoSurface({required BoxFit fit});
}

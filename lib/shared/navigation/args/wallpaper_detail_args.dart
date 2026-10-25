import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';

class WallpaperDetailArgs {
  const WallpaperDetailArgs({
    required this.subject,
    required this.initialUrl,
  });

  final SubjectWallpaper subject;
  final String initialUrl;
}

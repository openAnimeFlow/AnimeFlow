import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';

class WallpaperDetailArgs {
  WallpaperDetailArgs({
    required this.subject,
    required this.initialUrl,
    List<SubjectWallpaper> related = const [],
  }) : related = List.unmodifiable(related);

  final SubjectWallpaper subject;
  final String initialUrl;
  final List<SubjectWallpaper> related;
}

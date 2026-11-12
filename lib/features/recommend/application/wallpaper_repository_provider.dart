import 'package:anime_flow/features/recommend/domain/wallpaper_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wallpaperRepositoryProvider = Provider<WallpaperRepository>(
  (ref) => throw UnimplementedError('壁纸仓储必须由组合根提供'),
);

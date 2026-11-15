import 'package:anime_flow/features/recommend/application/wallpaper_favorites.dart';
import 'package:anime_flow/features/recommend/application/wallpaper_repository_provider.dart';
import 'package:anime_flow/features/recommend/data/wallpapers/wallpaper_remote_repository.dart';
import 'package:anime_flow/features/recommend/data/wallpapers/wallpaper_favorite_remote_repository.dart';

/// 把壁纸的 Data 实现绑定到 Application 契约上。
final wallpaperFeatureOverrides = [
  wallpaperRepositoryProvider
      .overrideWith((ref) => WallpaperRemoteRepository()),
  wallpaperFavoriteRepositoryProvider
      .overrideWith((ref) => WallpaperFavoriteRemoteRepository()),
];

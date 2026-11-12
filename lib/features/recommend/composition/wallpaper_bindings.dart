import 'package:anime_flow/features/recommend/application/wallpaper_recommendations.dart';
import 'package:anime_flow/features/recommend/application/wallpaper_favorites.dart';
import 'package:anime_flow/features/recommend/application/wallpaper_wall.dart';
import 'package:anime_flow/features/recommend/data/wallpapers/wallpaper_remote_loaders.dart';
import 'package:anime_flow/features/recommend/data/wallpapers/wallpaper_favorite_remote_repository.dart';

/// 把壁纸的 Data 实现绑定到 Application 契约上。
///
/// 只做创建与绑定，不承载业务规则；由 `app_overrides.dart` 注入应用级容器。
final wallpaperFeatureOverrides = [
  wallpaperFavoriteRepositoryProvider
      .overrideWith((ref) => WallpaperFavoriteRemoteRepository()),
  wallpaperPageLoaderProvider.overrideWith((ref) => requestWallpaperPage),
  wallpaperRecommendationsLoaderProvider
      .overrideWith((ref) => requestRecommendedWallpapers),
];

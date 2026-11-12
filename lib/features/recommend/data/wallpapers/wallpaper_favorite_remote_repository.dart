import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/features/recommend/domain/wallpaper_favorite_repository.dart';

class WallpaperFavoriteRemoteRepository implements WallpaperFavoriteRepository {
  @override
  Future<void> setFavorite(int subjectId, bool favorite) async {
    try {
      await FlowApi.setWallpaperFavorite(subjectId, favorite);
    } catch (_) {
      throw const WallpaperFavoriteFailure();
    }
  }
}

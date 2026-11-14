/// 当前用户的壁纸集合收藏写入能力。
abstract interface class WallpaperFavoriteRepository {
  Future<void> setFavorite(int subjectId, bool favorite);
}

/// 收藏状态未能保存。
class WallpaperFavoriteFailure implements Exception {
  const WallpaperFavoriteFailure();
}

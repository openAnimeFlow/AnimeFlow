import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/recommend/domain/wallpaper_favorite_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wallpaperFavoriteRepositoryProvider =
    Provider<WallpaperFavoriteRepository>(
  (ref) => throw UnimplementedError('壁纸收藏仓储必须由组合根提供'),
);

class WallpaperFavoritesState {
  const WallpaperFavoritesState(
      {this.changes = const {}, this.pending = const {}});

  final Map<int, bool> changes;
  final Set<int> pending;
}

/// 同一会话内共享收藏变更，并避免同一条目并发写入。
class WallpaperFavorites extends Notifier<WallpaperFavoritesState> {
  @override
  WallpaperFavoritesState build() {
    ref.watch(authSessionRevisionProvider);
    return const WallpaperFavoritesState();
  }

  Future<void> setFavorite(int subjectId, bool favorite) async {
    if (state.pending.contains(subjectId)) return;
    final revision = ref.read(authSessionRevisionProvider);
    final repository = ref.read(wallpaperFavoriteRepositoryProvider);
    state = WallpaperFavoritesState(
      changes: state.changes,
      pending: {...state.pending, subjectId},
    );
    try {
      await repository.setFavorite(subjectId, favorite);
      if (!ref.mounted || ref.read(authSessionRevisionProvider) != revision) {
        return;
      }
      state = WallpaperFavoritesState(
        changes: {...state.changes, subjectId: favorite},
        pending: {...state.pending}..remove(subjectId),
      );
    } catch (_) {
      if (!ref.mounted || ref.read(authSessionRevisionProvider) != revision) {
        return;
      }
      state = WallpaperFavoritesState(
        changes: state.changes,
        pending: {...state.pending}..remove(subjectId),
      );
      rethrow;
    }
  }
}

final wallpaperFavoritesProvider =
    NotifierProvider<WallpaperFavorites, WallpaperFavoritesState>(
        WallpaperFavorites.new);

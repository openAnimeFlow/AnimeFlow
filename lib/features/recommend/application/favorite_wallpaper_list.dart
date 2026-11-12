import 'dart:async';

import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/recommend/application/wallpaper_favorites.dart';
import 'package:anime_flow/features/recommend/application/wallpaper_repository_provider.dart';
import 'package:anime_flow/features/recommend/domain/wallpaper_repository.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoriteWallpaperListState {
  const FavoriteWallpaperListState({
    this.items = const [],
    this.total = 0,
    this.loading = false,
    this.hasMore = true,
    this.error,
  });
  final List<SubjectWallpaper> items;
  final int total;
  final bool loading;
  final bool hasMore;
  final Object? error;
}

class FavoriteWallpaperList extends Notifier<FavoriteWallpaperListState> {
  static const pageSize = 20;
  int _generation = 0;
  int _nextPage = 1;
  WallpaperCancellation? _cancel;
  bool _restartPagination = false;
  final Map<int, (SubjectWallpaper, int)> _removed = {};

  @override
  FavoriteWallpaperListState build() {
    ref.listen(authSessionRevisionProvider, (_, __) {
      _generation++;
      _cancel?.cancel();
      _nextPage = 1;
      _restartPagination = false;
      _removed.clear();
      state = const FavoriteWallpaperListState(hasMore: false);
    });
    ref.listen(wallpaperFavoritesProvider, (previous, next) {
      for (final entry in next.changes.entries) {
        if (previous?.changes[entry.key] != entry.value) {
          _applyFavoriteChange(entry.key, entry.value);
        }
      }
    });
    ref.onDispose(() {
      _generation++;
      _cancel?.cancel();
    });
    return const FavoriteWallpaperListState();
  }

  void _applyFavoriteChange(int subjectId, bool favorite) {
    // 页码以数据库中的记录数为基准；写入会改变偏移量，下次加载须重新对齐。
    _restartPagination = true;
    final wasLoading = state.loading;
    if (wasLoading) {
      _generation++;
      _cancel?.cancel();
    }
    final items = [...state.items];
    var total = state.total;
    final index = items.indexWhere((item) => item.subjectId == subjectId);
    if (!favorite && index >= 0) {
      _removed[subjectId] = (items.removeAt(index), index);
      if (total > 0) total--;
    } else if (favorite && index < 0) {
      final removed = _removed.remove(subjectId);
      if (removed != null) {
        items.insert(removed.$2.clamp(0, items.length), removed.$1);
        total++;
      }
    }
    state = FavoriteWallpaperListState(
      items: List.unmodifiable(items),
      total: total,
      hasMore: state.hasMore,
      error: state.error,
    );
    if (wasLoading || (items.isEmpty && total > 0 && state.hasMore)) {
      scheduleMicrotask(() {
        if (ref.mounted) unawaited(loadMore());
      });
    }
  }

  Future<void> refresh() async {
    _generation++;
    _cancel?.cancel();
    _nextPage = 1;
    _restartPagination = false;
    _removed.clear();
    state = const FavoriteWallpaperListState();
    await loadMore();
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    final generation = _generation;
    final token = _cancel = WallpaperCancellation();
    final existing = state.items;
    state = FavoriteWallpaperListState(
        items: existing, total: state.total, loading: true);
    try {
      final ids = existing.map((item) => item.subjectId).toSet();
      var page = _restartPagination ? 1 : _nextPage;
      while (true) {
        final result = await ref.read(wallpaperRepositoryProvider).getFavorites(
              page: page,
              pageSize: pageSize,
              cancellation: token,
            );
        if (!ref.mounted || generation != _generation) return;
        final added =
            result.items.where((item) => ids.add(item.subjectId)).toList();
        final hasMore =
            result.items.isNotEmpty && result.page * pageSize < result.total;
        page = result.page + 1;
        if (added.isNotEmpty || !hasMore) {
          _nextPage = page;
          _restartPagination = false;
          state = FavoriteWallpaperListState(
            items: List.unmodifiable([...existing, ...added]),
            total: result.total,
            hasMore: hasMore,
          );
          break;
        }
      }
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = FavoriteWallpaperListState(
          items: existing, total: state.total, error: error);
    }
  }
}

final favoriteWallpaperListProvider =
    NotifierProvider<FavoriteWallpaperList, FavoriteWallpaperListState>(
        FavoriteWallpaperList.new);

import 'dart:math';

import 'package:anime_flow/features/recommend/application/wallpaper_repository_provider.dart';
import 'package:anime_flow/features/recommend/domain/wallpaper_repository.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 壁纸墙条目：选择一个条目时即确定展示哪张图，滚动重排不会重新抽选。
class WallpaperPoster {
  const WallpaperPoster({required this.subject, required this.url});

  final SubjectWallpaper subject;
  final String url;

  bool get isBackdrop => subject.backdrops.contains(url);

  double get placeholderAspectRatio => isBackdrop ? 16 / 9 : 2 / 3;
}

class WallpaperWallState {
  const WallpaperWallState({
    this.items = const [],
    this.sort = SortType.trends,
    this.keyword = '',
    this.isLoading = false,
    this.hasMore = true,
    this.failure,
  });

  final List<WallpaperPoster> items;
  final SortType sort;

  final String keyword;
  final bool isLoading;
  final bool hasMore;
  final WallpaperFailure? failure;

  bool get isEmpty => items.isEmpty;

  WallpaperWallState copyWith({
    List<WallpaperPoster>? items,
    SortType? sort,
    String? keyword,
    bool? isLoading,
    bool? hasMore,
    WallpaperFailure? failure,
    bool clearFailure = false,
  }) =>
      WallpaperWallState(
        items: items ?? this.items,
        sort: sort ?? this.sort,
        keyword: keyword ?? this.keyword,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

final wallpaperRandomProvider = Provider<Random>((ref) => Random());

/// 壁纸墙用例：分页、筛选、去重、取消与代次控制都在这一层完成。
class WallpaperWall extends Notifier<WallpaperWallState> {
  static const pageSize = 20;

  int _generation = 0;
  int _nextPage = 1;
  final Set<int> _subjectIds = {};
  WallpaperCancellation? _cancelToken;
  late final Random _random;

  @override
  WallpaperWallState build() {
    _random = ref.watch(wallpaperRandomProvider);
    ref.onDispose(_cancelActive);
    return const WallpaperWallState();
  }

  /// 首次进入页面时拉取；已有数据或正在加载时保持现有结果。
  Future<void> ensureLoaded() {
    if (state.isLoading || state.items.isNotEmpty || state.failure != null) {
      return Future.value();
    }
    return refresh();
  }

  /// 重新拉取第一页；排序或关键词变化时由调用方传入新值。
  Future<void> refresh({SortType? sort, String? keyword}) {
    _generation++;
    _cancelActive();
    _subjectIds.clear();
    _nextPage = 1;
    state = state.copyWith(
      sort: sort,
      keyword: keyword?.trim(),
      items: const [],
      isLoading: false,
      hasMore: true,
      clearFailure: true,
    );
    return _load();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    await _load();
  }

  Future<void> _load() async {
    final generation = _generation;
    final cancelToken = _cancelToken = WallpaperCancellation();
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final result = await ref.read(wallpaperRepositoryProvider).getWallpapers(
            sort: state.sort,
            keyword: state.keyword.isEmpty ? null : state.keyword,
            page: _nextPage,
            pageSize: pageSize,
            cancellation: cancelToken,
          );
      if (generation != _generation) return;
      final items = [...state.items];
      for (final subject in result.items) {
        final candidates = subject.coverImages;
        if (candidates.isEmpty || !_subjectIds.add(subject.subjectId)) {
          continue;
        }
        items.add(WallpaperPoster(
          subject: subject,
          url: candidates[_random.nextInt(candidates.length)],
        ));
      }
      _nextPage = result.page + 1;
      state = state.copyWith(
        items: List.unmodifiable(items),
        isLoading: false,
        hasMore:
            result.items.isNotEmpty && result.page * pageSize < result.total,
      );
    } on WallpaperFailure catch (failure) {
      if (generation != _generation) return;
      // 取消由刷新/销毁触发，不属于用户可见的错误状态。
      state = state.copyWith(
        isLoading: false,
        failure:
            failure.kind == WallpaperFailureKind.cancelled ? null : failure,
      );
    } on Object catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(
        isLoading: false,
        failure: WallpaperFailure(
          WallpaperFailureKind.unknown,
          message: '$error',
        ),
      );
    } finally {
      if (generation == _generation && identical(_cancelToken, cancelToken)) {
        _cancelToken = null;
      }
    }
  }

  void _cancelActive() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }
}

final wallpaperWallProvider =
    NotifierProvider<WallpaperWall, WallpaperWallState>(WallpaperWall.new);

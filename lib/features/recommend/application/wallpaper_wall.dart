import 'dart:math';

import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 壁纸墙一页数据的来源契约：由 Data 实现、组合根注入。
typedef WallpaperPageLoader = Future<SubjectWallpaperPage> Function({
  required SortType sort,
  String? keyword,
  required int page,
  required int pageSize,
  CancelToken? cancelToken,
});

/// 业务失败语义：Data 已把技术异常转换到这里，Presentation 只负责呈现。
enum WallpaperWallFailureKind { network, timeout, cancelled, server, unknown }

class WallpaperWallFailure implements Exception {
  const WallpaperWallFailure(this.kind, {this.message});

  final WallpaperWallFailureKind kind;

  final String? message;

  @override
  String toString() => 'WallpaperWallFailure($kind, $message)';
}

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
  final WallpaperWallFailure? failure;

  bool get isEmpty => items.isEmpty;

  WallpaperWallState copyWith({
    List<WallpaperPoster>? items,
    SortType? sort,
    String? keyword,
    bool? isLoading,
    bool? hasMore,
    WallpaperWallFailure? failure,
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

/// 契约 provider：默认不提供实现，由组合根绑定 Data 层实现。
final wallpaperPageLoaderProvider = Provider<WallpaperPageLoader>(
  (ref) => throw UnimplementedError(
      'wallpaperPageLoaderProvider 必须由组合根 override 为 Data 实现'),
);

final wallpaperRandomProvider = Provider<Random>((ref) => Random());

/// 壁纸墙用例：分页、筛选、去重、取消与代次控制都在这一层完成。
class WallpaperWall extends Notifier<WallpaperWallState> {
  static const pageSize = 20;

  int _generation = 0;
  int _nextPage = 1;
  final Set<int> _subjectIds = {};
  CancelToken? _cancelToken;
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
    final cancelToken = _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final result = await ref.read(wallpaperPageLoaderProvider)(
        sort: state.sort,
        keyword: state.keyword.isEmpty ? null : state.keyword,
        page: _nextPage,
        pageSize: pageSize,
        cancelToken: cancelToken,
      );
      if (generation != _generation) return;
      final items = [...state.items];
      for (final subject in result.data) {
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
            result.data.isNotEmpty && result.page * pageSize < result.total,
      );
    } on WallpaperWallFailure catch (failure) {
      if (generation != _generation) return;
      // 取消由刷新/销毁触发，不属于用户可见的错误状态。
      state = state.copyWith(
        isLoading: false,
        failure:
            failure.kind == WallpaperWallFailureKind.cancelled ? null : failure,
      );
    } on Object catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(
        isLoading: false,
        failure: WallpaperWallFailure(
          WallpaperWallFailureKind.unknown,
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

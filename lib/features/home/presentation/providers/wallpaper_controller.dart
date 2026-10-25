import 'dart:math';

import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef WallpaperPageLoader = Future<SubjectWallpaperPage> Function({
  required SortType sort,
  required int page,
  required int pageSize,
  CancelToken? cancelToken,
});

class WallpaperPoster {
  const WallpaperPoster({required this.subject, required this.url});

  final SubjectWallpaper subject;
  final String url;

  bool get isBackdrop => subject.backdrops.contains(url);

  double get placeholderAspectRatio => isBackdrop ? 16 / 9 : 2 / 3;
}

/// Poster choices belong to loaded data, so rebuilding tiles never rerolls them.
class WallpaperController extends ChangeNotifier {
  static const _pageSize = 20;

  WallpaperController({WallpaperPageLoader? loader, Random? random})
      : _loader = loader ?? FlowApi.getSubjectWallpapersService,
        _random = random ?? Random();

  final WallpaperPageLoader _loader;
  final Random _random;
  final List<WallpaperPoster> _items = [];
  List<WallpaperPoster>? _itemsSnapshot;
  final Set<int> _subjectIds = {};
  CancelToken? _cancelToken;
  int _generation = 0;
  int _nextPage = 1;
  SortType sort = SortType.trends;
  bool isLoading = false;
  bool hasMore = true;
  Object? error;

  // Loading/error notifications reuse the same immutable data snapshot.
  List<WallpaperPoster> get items =>
      _itemsSnapshot ??= List.unmodifiable(_items);

  Future<void> refresh({SortType? sort}) {
    _generation++;
    _cancelToken?.cancel();
    if (sort != null) this.sort = sort;
    _items.clear();
    _itemsSnapshot = null;
    _subjectIds.clear();
    _nextPage = 1;
    isLoading = false;
    hasMore = true;
    error = null;
    return loadMore();
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;
    final generation = _generation;
    final cancelToken = _cancelToken = CancelToken();
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _loader(
        sort: sort,
        page: _nextPage,
        pageSize: _pageSize,
        cancelToken: cancelToken,
      );
      if (generation != _generation) return;
      for (final subject in result.data) {
        final candidates = subject.coverImages;
        if (candidates.isEmpty || !_subjectIds.add(subject.subjectId)) {
          continue;
        }
        _items.add(WallpaperPoster(
          subject: subject,
          url: candidates[_random.nextInt(candidates.length)],
        ));
        _itemsSnapshot = null;
      }
      _nextPage = result.page + 1;
      hasMore =
          result.data.isNotEmpty && result.page * _pageSize < result.total;
    } catch (e) {
      if (generation != _generation) return;
      error = e;
    } finally {
      if (generation == _generation) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _cancelToken?.cancel();
    super.dispose();
  }
}

import 'dart:async';

import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';

/// 跨界面的壁纸条目是共享业务模型，分页不包含网络响应对象。
class WallpaperPage {
  const WallpaperPage(
      {required this.items, required this.page, required this.total});
  final List<SubjectWallpaper> items;
  final int page;
  final int total;
}

/// 不依赖网络库的请求取消信号。
class WallpaperCancellation {
  final Completer<void> _cancelled = Completer<void>();
  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;
  void cancel() {
    if (!isCancelled) _cancelled.complete();
  }
}

enum WallpaperFailureKind { network, timeout, cancelled, server, unknown }

class WallpaperFailure implements Exception {
  const WallpaperFailure(this.kind, {this.message});
  final WallpaperFailureKind kind;
  final String? message;

  @override
  String toString() => 'WallpaperFailure($kind, $message)';
}

abstract interface class WallpaperRepository {
  Future<WallpaperPage> getWallpapers({
    required SortType sort,
    String? keyword,
    required int page,
    required int pageSize,
    WallpaperCancellation? cancellation,
  });

  Future<WallpaperPage> getFavorites({
    required int page,
    required int pageSize,
    WallpaperCancellation? cancellation,
  });

  Future<List<SubjectWallpaper>> getRecommendations(int subjectId,
      {WallpaperCancellation? cancellation});
}

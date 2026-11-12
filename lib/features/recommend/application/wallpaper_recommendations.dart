import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 条目相关壁纸查询契约，由 Data 实现、组合根注入。
typedef WallpaperRecommendationsLoader = Future<List<SubjectWallpaper>>
    Function(int subjectId, {CancelToken? cancelToken});

final wallpaperRecommendationsLoaderProvider =
    Provider<WallpaperRecommendationsLoader>(
  (ref) => throw UnimplementedError(
      'wallpaperRecommendationsLoaderProvider 必须由组合根 override 为 Data 实现'),
);

/// 某个条目的相关壁纸；离开详情页（失去订阅）即取消在途请求。
final wallpaperRecommendationsProvider =
    FutureProvider.autoDispose.family<List<SubjectWallpaper>, int>(
  (ref, subjectId) {
    ref.watch(authSessionRevisionProvider);
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);
    return ref.watch(wallpaperRecommendationsLoaderProvider)(
      subjectId,
      cancelToken: cancelToken,
    );
  },
  retry: (_, __) => null,
);

import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/recommend/application/wallpaper_repository_provider.dart';
import 'package:anime_flow/features/recommend/domain/wallpaper_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 某个条目的相关壁纸；离开详情页（失去订阅）即取消在途请求。
final wallpaperRecommendationsProvider =
    FutureProvider.autoDispose.family<List<SubjectWallpaper>, int>(
  (ref, subjectId) async {
    ref.watch(authSessionRevisionProvider);
    final cancelToken = WallpaperCancellation();
    ref.onDispose(cancelToken.cancel);
    final items = await ref
        .watch(wallpaperRepositoryProvider)
        .getRecommendations(subjectId, cancellation: cancelToken);
    final seen = <int>{subjectId};
    return items
        .where(
            (item) => item.coverImages.isNotEmpty && seen.add(item.subjectId))
        .toList(growable: false);
  },
  retry: (_, __) => null,
);

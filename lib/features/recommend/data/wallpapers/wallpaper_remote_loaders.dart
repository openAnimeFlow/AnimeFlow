import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/network/core/flow_response.dart';
import 'package:anime_flow/core/network/core/network_exception.dart';
import 'package:anime_flow/features/recommend/application/wallpaper_wall.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:dio/dio.dart' show CancelToken;

/// 壁纸墙一页数据。
Future<SubjectWallpaperPage> requestWallpaperPage({
  required SortType sort,
  String? keyword,
  required int page,
  required int pageSize,
  CancelToken? cancelToken,
}) async {
  try {
    return await FlowApi.getSubjectWallpapersService(
      sort: sort,
      keyword: keyword,
      page: page,
      pageSize: pageSize,
      cancelToken: cancelToken,
    );
  } catch (error) {
    throw _toFailure(error);
  }
}

/// 某个条目的相关壁纸；去重与空封面过滤属于查询语义。
Future<List<SubjectWallpaper>> requestRecommendedWallpapers(
  int subjectId, {
  CancelToken? cancelToken,
}) async {
  try {
    final response = await FlowApi.getRecommendedWallpapersService(
      subjectId,
      cancelToken: cancelToken,
    );
    final seen = <int>{subjectId};
    return response.data
        .where((subject) =>
            subject.coverImages.isNotEmpty && seen.add(subject.subjectId))
        .toList(growable: false);
  } catch (error) {
    throw _toFailure(error);
  }
}

WallpaperWallFailure _toFailure(Object error) {
  if (error is WallpaperWallFailure) return error;
  if (error is AnimeFlowApiException) {
    final message = error.message.trim();
    return WallpaperWallFailure(
      WallpaperWallFailureKind.server,
      message: message.isEmpty ? null : message,
    );
  }
  if (error is NetworkException) {
    final message = error.message.trim();
    return WallpaperWallFailure(
      switch (error.type) {
        NetworkExceptionType.cancel => WallpaperWallFailureKind.cancelled,
        NetworkExceptionType.connectionTimeout ||
        NetworkExceptionType.receiveTimeout ||
        NetworkExceptionType.sendTimeout ||
        NetworkExceptionType.transformTimeout =>
          WallpaperWallFailureKind.timeout,
        NetworkExceptionType.badResponse ||
        NetworkExceptionType.parseError =>
          WallpaperWallFailureKind.server,
        NetworkExceptionType.connectionError ||
        NetworkExceptionType.badCertificate ||
        NetworkExceptionType.unknown =>
          WallpaperWallFailureKind.network,
      },
      message: message.isEmpty ? null : message,
    );
  }
  return const WallpaperWallFailure(WallpaperWallFailureKind.unknown);
}

import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/network/core/flow_response.dart';
import 'package:anime_flow/core/network/core/network_exception.dart';
import 'package:anime_flow/features/recommend/domain/wallpaper_repository.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:dio/dio.dart' show CancelToken;

class WallpaperRemoteDataSource {
  Future<Map<String, dynamic>> getWallpapers(
          {required SortType sort,
          String? keyword,
          required int page,
          required int pageSize,
          required CancelToken cancelToken}) =>
      FlowApi.getSubjectWallpapersService(
          sort: sort,
          keyword: keyword,
          page: page,
          pageSize: pageSize,
          cancelToken: cancelToken);

  Future<Map<String, dynamic>> getFavorites(
          {required int page,
          required int pageSize,
          required CancelToken cancelToken}) =>
      FlowApi.getFavoriteWallpapersService(
          page: page, pageSize: pageSize, cancelToken: cancelToken);

  Future<Map<String, dynamic>> getRecommendations(int subjectId,
          {required CancelToken cancelToken}) =>
      FlowApi.getRecommendedWallpapersService(subjectId,
          cancelToken: cancelToken);
}

class WallpaperRemoteRepository implements WallpaperRepository {
  WallpaperRemoteRepository({WallpaperRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? WallpaperRemoteDataSource();

  final WallpaperRemoteDataSource _dataSource;
  @override
  Future<WallpaperPage> getWallpapers({
    required SortType sort,
    String? keyword,
    required int page,
    required int pageSize,
    WallpaperCancellation? cancellation,
  }) =>
      _request(
          cancellation,
          (token) => _dataSource.getWallpapers(
                sort: sort,
                keyword: keyword,
                page: page,
                pageSize: pageSize,
                cancelToken: token,
              ));

  @override
  Future<WallpaperPage> getFavorites({
    required int page,
    required int pageSize,
    WallpaperCancellation? cancellation,
  }) =>
      _request(
          cancellation,
          (token) => _dataSource.getFavorites(
                page: page,
                pageSize: pageSize,
                cancelToken: token,
              ));

  @override
  Future<List<SubjectWallpaper>> getRecommendations(int subjectId,
      {WallpaperCancellation? cancellation}) async {
    final result = await _request(
        cancellation,
        (token) =>
            _dataSource.getRecommendations(subjectId, cancelToken: token));
    return result.items;
  }

  Future<WallpaperPage> _request(WallpaperCancellation? cancellation,
      Future<Map<String, dynamic>> Function(CancelToken) request) async {
    final token = CancelToken();
    if (cancellation != null) {
      if (cancellation.isCancelled) {
        throw const WallpaperFailure(WallpaperFailureKind.cancelled);
      }
      cancellation.whenCancelled.then((_) => token.cancel());
    }
    try {
      return wallpaperPageFromJson(await request(token));
    } catch (error) {
      throw _toFailure(error);
    }
  }
}

WallpaperPage wallpaperPageFromJson(Map<String, dynamic> json) => WallpaperPage(
      items: (json['data'] as List).map((raw) {
        final item = Map<String, dynamic>.from(raw as Map);
        List<String> images(String key) => (item[key] as List? ?? const [])
            .whereType<String>()
            .where((url) => url.trim().isNotEmpty)
            .toList(growable: false);
        return SubjectWallpaper(
          subjectId: item['subjectId'] as int,
          name: item['name'] as String? ?? '',
          nameCn: item['nameCn'] as String? ?? '',
          favorite: item['favorite'] as bool?,
          backdrops: images('backdrops'),
          posters: images('posters'),
        );
      }).toList(growable: false),
      page: json['page'] as int,
      total: json['total'] as int,
    );

WallpaperFailure _toFailure(Object error) {
  if (error is WallpaperFailure) return error;
  if (error is AnimeFlowApiException) {
    final message = error.message.trim();
    return WallpaperFailure(WallpaperFailureKind.server,
        message: message.isEmpty ? null : message);
  }
  if (error is NetworkException) {
    final message = error.message.trim();
    return WallpaperFailure(
      switch (error.type) {
        NetworkExceptionType.cancel => WallpaperFailureKind.cancelled,
        NetworkExceptionType.connectionTimeout ||
        NetworkExceptionType.receiveTimeout ||
        NetworkExceptionType.sendTimeout ||
        NetworkExceptionType.transformTimeout =>
          WallpaperFailureKind.timeout,
        NetworkExceptionType.badResponse ||
        NetworkExceptionType.parseError =>
          WallpaperFailureKind.server,
        NetworkExceptionType.connectionError ||
        NetworkExceptionType.badCertificate ||
        NetworkExceptionType.unknown =>
          WallpaperFailureKind.network,
      },
      message: message.isEmpty ? null : message,
    );
  }
  return const WallpaperFailure(WallpaperFailureKind.unknown);
}

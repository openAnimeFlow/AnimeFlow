import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/clients/ligg_client.dart';
import 'package:anime_flow/shared/models/github_release.dart';
import 'package:dio/dio.dart';

class LiggApi {
  static final LiggClient _client = LiggClient.instance;

  /// 获取 AnimeFlow 发布版本列表。
  static Future<List<GithubRelease>> getReleases({
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final response = await _client.get<List<dynamic>>(
      AnimeFlowApi.releases,
      queryParameters: {
        'page': page,
      },
      cancelToken: cancelToken,
    );
    final data = response.data;
    if (data == null) return const [];

    return data
        .whereType<Map>()
        .map((item) => GithubRelease.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}

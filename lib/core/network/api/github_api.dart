import 'dart:convert';

import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/clients/rules_repo_client.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/network/core/network_error_mapper.dart';
import 'package:anime_flow/core/settings/rules_mirror.dart';
import 'package:anime_flow/shared/models/font_item.dart';
import 'package:dio/dio.dart';

class GithubApi {
  static final _client = RulesRepoClient.instance;

  /// 获取仓库字体列表
  static Future<List<FontItem>> getRepoFonts({
    required RulesMirror mirror,
    CancelToken? cancelToken,
  }) async {
    final text = await _client.getText(
      '${CommonApi.fontRepo}/index.json',
      mirror: mirror,
      cancelToken: cancelToken,
    );
    final list = jsonDecode(text) as List<dynamic>;

    return list
        .map((item) => FontItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 预览字体
  static Future<List<int>> previewFont(
    String fontUrl, {
    required RulesMirror mirror,
    CancelToken? cancelToken,
  }) =>
      _client.getBytes(
        fontUrl,
        mirror: mirror,
        cancelToken: cancelToken,
      );

  /// 下载字体文件到指定路径
  static Future<void> downloadFontToFile(
    String fontUrl,
    String savePath, {
    required RulesMirror mirror,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Use the streaming adapter for large files and gh-proxy ECH support.
      await DioFactory.appUpdateDio.download(
        RulesRepoClient.resolveUrl(fontUrl, mirror),
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw await NetworkErrorMapper.mapException(error);
    }
  }
}

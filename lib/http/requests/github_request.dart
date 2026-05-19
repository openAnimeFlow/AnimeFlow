import 'dart:convert';

import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/clients/github_client.dart';
import 'package:anime_flow/models/item/font_item.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:dio/dio.dart';

class GithubRequest {
  static final GithubClient _client = GithubClient.instance;

  /// 获取仓库字体列表
  static Future<List<FontItem>> getRepoFonts({bool useCdn = false}) async {
    var fontRepoUrl = '${CommonApi.fontRepo}/index.json';
    if (useCdn) {
      fontRepoUrl = Utils.jsDelivrCdnUrl(fontRepoUrl);
    }

    final response = await _client.get(fontRepoUrl);
    final List<dynamic> list;
    if (response.data is String) {
      list = jsonDecode(response.data as String) as List<dynamic>;
    } else {
      list = response.data as List<dynamic>;
    }

    return list
        .map((item) => FontItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// 预览字体
  static Future<List<int>> previewFont(
    String fontUrl, {
    bool useCdn = false,
    CancelToken? cancelToken,
  }) async {
    if (useCdn) {
      fontUrl = Utils.jsDelivrCdnUrl(fontUrl);
    }
    final response = await _client.get(
      fontUrl,
      options: Options(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
    );
    return response.data;
  }

  /// 下载字体文件到指定路径
  static Future<void> downloadFontToFile(
    String fontUrl,
    String savePath, {
    bool useCdn = false,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    if (useCdn) {
      fontUrl = Utils.jsDelivrCdnUrl(fontUrl);
    }
    await _client.download(
      fontUrl,
      savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }
}

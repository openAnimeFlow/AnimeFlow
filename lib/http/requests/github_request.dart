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

  ///下载字体
  static Future<List<int>> downloadFont(String fontUrl,{bool useCdn = false}) async {
    if (useCdn) {
      fontUrl = Utils.jsDelivrCdnUrl(fontUrl);
    }
    final response = await _client.get(fontUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }
}

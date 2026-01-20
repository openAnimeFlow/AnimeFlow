import 'dart:convert';

import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';

class Request {
  static Future<Map<String, dynamic>> getReleases() async {
    return await dioRequest
        .get(CommonApi.githubApi + CommonApi.animeFlowVersion)
        .then((onValue) => onValue.data);
  }

  ///获取插件列表
  static Future<List<dynamic>> getPluginRepo() async {
    return await dioRequest
        .get(CommonApi.githubApi + CommonApi.pluginRepo)
        .then((onValue) => onValue.data as List<dynamic>);
  }

  ///获取插件数据
  static Future<CrawlConfigItem> getPlugin(String downloadUrl) async {
    return await dioRequest.get(downloadUrl).then((onValue) {
      Map<String, dynamic> jsonData;
      if (onValue.data is String) {
        jsonData = jsonDecode(onValue.data as String) as Map<String, dynamic>;
      } else {
        jsonData = onValue.data as Map<String, dynamic>;
      }
      return CrawlConfigItem.fromJson(jsonData);
    });
  }
}

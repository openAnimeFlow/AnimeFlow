import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/crawler/html_crawler.dart';
import 'package:anime_flow/crawler/itme/bgm_user_page_item.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/http/clients/client.dart';
import 'package:anime_flow/models/item/image_search_item.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart'
    show getDownloadsDirectory, getTemporaryDirectory;

class Request {
  static final Client _client = Client.instance;

  static Future<Map<String, dynamic>> getReleases() async {
    return await _client
        .get(CommonApi.githubApi + CommonApi.animeFlowVersion)
        .then((onValue) => onValue.data);
  }

  ///获取插件列表
  static Future<List<dynamic>> getPluginRepo({bool isMirror = false}) async {
    var pluginRepo = '${CommonApi.pluginRepo}/index.json';
    if (isMirror) {
      pluginRepo = '${CommonApi.gitMirror}$pluginRepo';
    }

    return await _client
        .get(pluginRepo,
        options: Options(headers: {
          Constants.userAgentName: Utils.getRandomUA(),
        }))
        .then((onValue) {
      if (onValue.data is String) {
        return jsonDecode(onValue.data as String) as List<dynamic>;
      } else {
        return onValue.data as List<dynamic>;
      }
    });
  }

  ///获取插件数据
  static Future<CrawlConfigItem> getPlugin(String downloadUrl,{bool isMirror = false}) async {
    if (isMirror) downloadUrl = '${CommonApi.gitMirror}$downloadUrl';

    return await _client.get(downloadUrl).then((onValue) {
      Map<String, dynamic> jsonData;
      if (onValue.data is String) {
        jsonData = jsonDecode(onValue.data as String) as Map<String, dynamic>;
      } else {
        jsonData = onValue.data as Map<String, dynamic>;
      }
      return CrawlConfigItem.fromJson(jsonData);
    });
  }

  ///获取bgm用户页面数据
  static Future<BgmUserPageItem> getBgmUserPageService(String username) async {
    final response = await _client.get(
      '${CommonApi.bgmTV}/user/$username',
      options: Options(
        headers: {Constants.userAgentName: Utils.getRandomUA()},
      ),
    );
    return await HtmlCrawler.parseUserPage(response.data);
  }

  /// 图片识别番剧 [file]
  static Future<ImageSearchItem> getAnimeInfoByImageFile(
      File imageFile,
      {int anilistInfo = 2}) async {
    final bytes = await imageFile.readAsBytes();

    return await _client
        .post(
      CommonApi.traceApi,
      queryParameters: {"anilistInfo": anilistInfo},
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': 'image/jpeg',
        },
      ),
    )
        .then((onValue) {
      return ImageSearchItem.fromJson(
          onValue.data as Map<String, dynamic>);
    });
  }

  /// 图片识别番剧 [url]
  static Future<ImageSearchItem> getAnimeInfoByImageUrl(
      String imageUrl,
      {int anilistInfo = 2}) async {
    return await _client.post(
      CommonApi.traceApi,
      queryParameters: {"anilistInfo": anilistInfo, "url": imageUrl},
    ).then((onValue) {
      return ImageSearchItem.fromJson(
          onValue.data as Map<String, dynamic>);
    });
  }

  static Future<void> downloadImage(String url, String name) async {
    try {
      final String time = DateTime.now().millisecondsSinceEpoch.toString();
      if (SystemUtil.isMobile) {
        /*
          移动端(保持到相册)
          检查并申请存储权限
        */
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          bool granted = await Gal.requestAccess();
          if (!granted) {
            Get.snackbar('提示', '存储权限被拒绝，无法保存图片', maxWidth: 500);
            throw Exception('存储权限被拒绝，无法保存图片');
          }
        }
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$time.jpg';
        await _client.download(url, filePath);
        final bytes = await File(filePath).readAsBytes();
        await Gal.putImageBytes(bytes, name: '${name}_$time');
        await File(filePath).delete();
        Get.snackbar('提示', '图片已保存到相册', maxWidth: 500);
      } else {
        //桌面端(保持到下载目录)
        final dir = await getDownloadsDirectory();
        final filePath = '${dir?.path}/${name}_$time.jpg';
        await _client.download(url, filePath);
        Logger().i('图片已保存到:$filePath');
        Get.snackbar('提示', '图片已保存到:$filePath', maxWidth: 500);
      }
    } catch (e) {
      Get.snackbar('提示', '保存图片失败:$e', maxWidth: 500);
      Logger().e('保存图片失败:$e');
    }
  }
}

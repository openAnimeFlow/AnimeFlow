import 'dart:io';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/crawler/html_crawler.dart';
import 'package:anime_flow/crawler/itme/bgm_user_page_item.dart';
import 'package:anime_flow/network/api_path.dart';
import 'package:anime_flow/network/clients/client.dart';
import 'package:anime_flow/models/item/image_search_item.dart';
import 'package:anime_flow/utils/exceptions/storage_exception.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class Api {
  static final Client _client = Client.instance;

  /// 获取资源，返回原始响应数据
  static Future<T> getResources<T>(String url, {Options? options}) async {
    return (await _client.get(
      url,
      options: options ??
          Options(headers: {
            Constants.userAgentName: Utils.getRandomUA(),
          }),
    ))
        .data as T;
  }

  /// 资源下载
  static Future<void> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    await _client.download(
      url,
      savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  ///获取bgm用户统计数据
  static Future<BgmUserStatisticsItem> getBgmUserStatisticsService(
      String username) async {
    final response = await _client.get(
      '${CommonApi.bgmTV}/user/$username',
      options: Options(
        headers: {Constants.userAgentName: Utils.getRandomUA()},
      ),
    );
    return await HtmlCrawler.parseUserPage(response.data);
  }

  /// 图片识别番剧 [file]
  static Future<ImageSearchItem> getAnimeInfoByImageFile(File imageFile,
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
      return ImageSearchItem.fromJson(onValue.data as Map<String, dynamic>);
    });
  }

  /// 图片识别番剧 [url]
  static Future<ImageSearchItem> getAnimeInfoByImageUrl(String imageUrl,
      {int anilistInfo = 2}) async {
    return await _client.post(
      CommonApi.traceApi,
      queryParameters: {"anilistInfo": anilistInfo, "url": imageUrl},
    ).then((onValue) {
      return ImageSearchItem.fromJson(onValue.data as Map<String, dynamic>);
    });
  }

  /// 下载图片，成功时返回提示文案。
  static Future<String> downloadImage(String url, String name) async {
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
          throw const StoragePermissionDeniedException();
        }
      }
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$time.jpg';
      await _client.download(url, filePath);
      final bytes = await File(filePath).readAsBytes();
      await Gal.putImageBytes(bytes, name: '${name}_$time');
      await File(filePath).delete();
      return '图片已保存到相册';
    } else {
      //桌面端(保持到下载目录)
      final dir = await getDownloadsDirectory();
      final filePath = '${dir?.path}/${name}_$time.jpg';
      await _client.download(url, filePath);
      LiggLogger().i('图片已保存到:$filePath');
      return '图片已保存到:$filePath';
    }
  }
}

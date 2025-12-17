import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:anime_flow/constants/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

class Utils {
  static Logger logger = Logger();

  ///初始化爬虫配置
  static Future<void> initCrawlConfigs() async {
    final box = Hive.box(Constants.crawlConfigs);

    // 插件文件列表
    final pluginFiles = [
      'assets/plugins/girigiri.json',
      'assets/plugins/xfdm.json',
      'assets/plugins/yzk.json',
    ];

    for (final path in pluginFiles) {
      try {
        final jsonStr = await rootBundle.loadString(path);
        final config = jsonDecode(jsonStr);

        final name = config['name'];
        final version = config['version'];
        if (!box.containsKey(name) || box.get(name)['version'] != version) {
          await box.put(name, config);
          logger.i('已加载配置：$name,版本：$version');
        }
      } catch (e) {
        logger.e('加载配置失败：$path, 错误：$e');
      }
    }
  }

  // 从URL参数中解析 m3u8/mp4
  static String decodeVideoSource(String iframeUrl) {
    var decodedUrl = Uri.decodeFull(iframeUrl);
    RegExp regExp = RegExp(r'(http[s]?://.*?\.m3u8)|(http[s]?://.*?\.mp4)',
        caseSensitive: false);

    Uri uri = Uri.parse(decodedUrl);
    Map<String, String> params = uri.queryParameters;

    String matchedUrl = iframeUrl;
    params.forEach((key, value) {
      if (regExp.hasMatch(value)) {
        matchedUrl = value;
        return;
      }
    });

    return Uri.encodeFull(matchedUrl);
  }

  // 获取随机UA
  static String getRandomUA() {
    final random = Random();
    String randomElement =
        Constants.userAgentList[random.nextInt(Constants.userAgentList.length)];
    return randomElement;
  }

  static bool? _isDocumentStartScriptSupported;

  /// 检查 Android WebView 是否支持 DOCUMENT_START_SCRIPT 特性
  static Future<void> checkWebViewFeatureSupport() async {
    if (Platform.isAndroid) {
      _isDocumentStartScriptSupported = await PlatformWebViewFeature.static()
          .isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT);
    }
  }

  static bool get isDocumentStartScriptSupported =>
      _isDocumentStartScriptSupported ?? false;

}

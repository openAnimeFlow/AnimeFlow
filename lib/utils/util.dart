import 'dart:convert';

import 'package:anime_flow/constants/constants.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

class Util {
  static Logger logger = Logger();

  ///初始化爬虫配置
  static Future<void> initCrawlConfigs() async {
    final box = Hive.box(Constants.crawlConfigs);

    // 插件文件列表
    final pluginFiles = [
      'assets/plugins/girigiri.json',
      'assets/plugins/xfdm.json',
    ];

    for (final path in pluginFiles) {
      try {
        final jsonStr = await rootBundle.loadString(path);
        final config = jsonDecode(jsonStr);

        final name = config['name'];
        final version = config['version'];
        if (!box.containsKey(name) || box.get(name)['version'] != version) {
          await box.put(name, config);
          logger.i('已加载配置：$name版本：$version');
        }
      } catch (e) {
        logger.e('加载配置失败：$path, 错误：$e');
      }
    }
  }
}

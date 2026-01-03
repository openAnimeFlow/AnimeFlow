import 'dart:convert';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

class CrawlConfig {
  static final Logger logger = Logger();
  static final box = Hive.box(Constants.crawlConfigs);

  ///读取所有配置
  static Future<List<CrawlConfigItem>> loadAllCrawlConfigs() async {
    return box.values
        .map((value) => CrawlConfigItem.fromJson(
              Map<String, dynamic>.from(value),
            ))
        .toList();
  }

  ///初始化爬虫配置
  static Future<void> initCrawlConfigs() async {
    // 插件文件列表
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = assetManifest.listAssets();
    final jsonFiles = assets.where((String asset) =>
    asset.startsWith('assets/plugins/') && asset.endsWith('.json'));

    for (final path in jsonFiles) {
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

  ///添加配置
  static Future<void> saveCrawl(CrawlConfigItem crawlConfig) async {
    try {
      await box.put(crawlConfig.name, crawlConfig.toJson());
    } catch (e) {
      logger.e('保存配置失败：$e');
    }
  }

  ///删除配置
  static Future<void> deleteCrawl(String key) async {
    try {
      await box.delete(key);
    } catch (e) {
      logger.e('删除配置失败：$e');
    }
  }
}

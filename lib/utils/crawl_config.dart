import 'dart:convert';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

class CrawlConfig {
  static final Logger logger = Logger();

  //读取所有配置
  static Future<List<CrawlConfigItem>> loadAllCrawlConfigs() async {
    final box = Hive.box(Constants.crawlConfigs);

    return box.values
        .map((value) => CrawlConfigItem.fromJson(
              Map<String, dynamic>.from(value),
            ))
        .toList();
  }
}

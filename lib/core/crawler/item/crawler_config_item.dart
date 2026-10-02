import 'anti_crawler_config.dart';
import 'package:hive_ce/hive.dart';

part 'crawler_config_item.g.dart';

@HiveType(typeId: 12)
class CrawlConfigItem {
  @HiveField(0)
  final String version;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String iconUrl;
  @HiveField(3)
  final String baseUrl;
  @HiveField(4)
  final String searchUrl;
  @HiveField(5)
  final String searchList;
  @HiveField(6)
  final String searchName;
  @HiveField(7)
  final String searchLink;
  @HiveField(8)
  final String lineNames;
  @HiveField(9)
  final String lineList;
  @HiveField(10)
  final String episode;
  @HiveField(11)
  AntiCrawlerConfig antiCrawlerConfig;

  CrawlConfigItem({
    required this.version,
    required this.name,
    required this.iconUrl,
    required this.baseUrl,
    required this.searchUrl,
    required this.searchList,
    required this.searchName,
    required this.searchLink,
    required this.lineNames,
    required this.lineList,
    required this.episode,
    AntiCrawlerConfig? antiCrawlerConfig,
  }) : antiCrawlerConfig = antiCrawlerConfig ?? AntiCrawlerConfig.empty();

  factory CrawlConfigItem.fromJson(Map<String, dynamic> json) {
    return CrawlConfigItem(
        version: json['version'] ?? '',
        name: json['name'] ?? '',
        iconUrl: json['iconUrl'] ?? '',
        baseUrl: json['baseUrl'] ?? '',
        searchUrl: json['searchUrl'] ?? '',
        searchList: json['searchList'] ?? '',
        searchName: json['searchName'] ?? '',
        searchLink: json['searchLink'] ?? '',
        lineNames: json['lineNames'] ?? '',
        lineList: json['lineList'] ?? '',
        episode: json['episode'] ?? '',
        antiCrawlerConfig: json['antiCrawlerConfig'] != null
            ? AntiCrawlerConfig.fromJson(
                Map<String, dynamic>.from(json['antiCrawlerConfig']))
            : AntiCrawlerConfig.empty());
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'name': name,
      'iconUrl': iconUrl,
      'baseUrl': baseUrl,
      'searchUrl': searchUrl,
      'searchList': searchList,
      'searchName': searchName,
      'searchLink': searchLink,
      'lineNames': lineNames,
      'lineList': lineList,
      'episode': episode,
      'antiCrawlerConfig': antiCrawlerConfig.toJson(),
    };
  }

  @override
  String toString() {
    return 'CrawlConfigItem{version: $version, name: $name, iconUrl: $iconUrl, baseUrl: $baseUrl, searchUrl: $searchUrl, searchList: $searchList, searchName: $searchName, searchLink: $searchLink, lineNames: $lineNames, lineList: $lineList, episode: $episode, antiCrawlerConfig: $antiCrawlerConfig}';
  }
}

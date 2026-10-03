import 'anti_crawler_config.dart';
import 'api_rule_config.dart';
import 'package:hive_ce/hive.dart';
import '../rule_api_level.dart';

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

  /// 搜索模式，见 [RuleMode]，默认 [RuleMode.xpath]。
  @HiveField(12)
  String searchMode;

  /// 章节模式，见 [RuleMode]，默认 [RuleMode.xpath]。
  @HiveField(13)
  String chapterMode;

  /// API 搜索配置；XPath 模式下仍然保留，切换模式后不丢失。
  @HiveField(14)
  ApiSearchConfig searchApiConfig;

  /// API 章节配置；XPath 模式下仍然保留，切换模式后不丢失。
  @HiveField(15)
  ApiChapterConfig chapterApiConfig;

  /// 规则要求的客户端规则 API 级别，见 [RuleApiLevel]。
  @HiveField(16)
  String api;

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
    String? searchMode,
    String? chapterMode,
    ApiSearchConfig? searchApiConfig,
    ApiChapterConfig? chapterApiConfig,
    String? api,
  })  : antiCrawlerConfig = antiCrawlerConfig ?? AntiCrawlerConfig.empty(),
        searchMode = RuleMode.normalize(searchMode),
        chapterMode = RuleMode.normalize(chapterMode),
        searchApiConfig = searchApiConfig ?? ApiSearchConfig(),
        chapterApiConfig = chapterApiConfig ?? ApiChapterConfig(),
        api = _normalizeApiLevel(api);

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
            : AntiCrawlerConfig.empty(),
        searchMode: json['searchMode']?.toString(),
        chapterMode: json['chapterMode']?.toString(),
        searchApiConfig: json['searchApiConfig'] is Map
            ? ApiSearchConfig.fromJson(
                Map<String, dynamic>.from(json['searchApiConfig']))
            : null,
        chapterApiConfig: json['chapterApiConfig'] is Map
            ? ApiChapterConfig.fromJson(
                Map<String, dynamic>.from(json['chapterApiConfig']))
            : null,
        api: json['api']?.toString());
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
      'searchMode': searchMode,
      'chapterMode': chapterMode,
      // 持久化/导出会重写整份规则，未激活模式的一侧也必须保留。
      if (usesApiSearch || searchApiConfig.request.url.isNotEmpty)
        'searchApiConfig': searchApiConfig.toJson(),
      if (usesApiChapter || chapterApiConfig.request.url.isNotEmpty)
        'chapterApiConfig': chapterApiConfig.toJson(),
      'api': api,
    };
  }

  bool get usesApiSearch => searchMode == RuleMode.api;

  bool get usesApiChapter => chapterMode == RuleMode.api;

  /// 规则文件与当前客户端的兼容性，见 [RuleApiLevel.check]。
  RuleCompatibility get ruleCompatibility => RuleApiLevel.check(api);

  bool get isRuleCompatible =>
      ruleCompatibility == RuleCompatibility.compatible;

  bool get requiresNewerClient =>
      ruleCompatibility == RuleCompatibility.requiresNewerClient;

  /// 复制并覆盖部分字段。
  ///
  /// [antiCrawlerConfig] 等有默认值的字段传 null 时保持原值。
  CrawlConfigItem copyWith({
    String? version,
    String? name,
    String? iconUrl,
    String? baseUrl,
    String? searchUrl,
    String? searchList,
    String? searchName,
    String? searchLink,
    String? lineNames,
    String? lineList,
    String? episode,
    AntiCrawlerConfig? antiCrawlerConfig,
    String? searchMode,
    String? chapterMode,
    ApiSearchConfig? searchApiConfig,
    ApiChapterConfig? chapterApiConfig,
    String? api,
  }) {
    return CrawlConfigItem(
      version: version ?? this.version,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      baseUrl: baseUrl ?? this.baseUrl,
      searchUrl: searchUrl ?? this.searchUrl,
      searchList: searchList ?? this.searchList,
      searchName: searchName ?? this.searchName,
      searchLink: searchLink ?? this.searchLink,
      lineNames: lineNames ?? this.lineNames,
      lineList: lineList ?? this.lineList,
      episode: episode ?? this.episode,
      antiCrawlerConfig: antiCrawlerConfig ?? this.antiCrawlerConfig,
      searchMode: searchMode ?? this.searchMode,
      chapterMode: chapterMode ?? this.chapterMode,
      searchApiConfig: searchApiConfig ?? this.searchApiConfig,
      chapterApiConfig: chapterApiConfig ?? this.chapterApiConfig,
      api: api ?? this.api,
    );
  }

  @override
  String toString() {
    return 'CrawlConfigItem{version: $version, name: $name, iconUrl: $iconUrl, baseUrl: $baseUrl, searchUrl: $searchUrl, searchList: $searchList, searchName: $searchName, searchLink: $searchLink, lineNames: $lineNames, lineList: $lineList, episode: $episode, antiCrawlerConfig: $antiCrawlerConfig, searchMode: $searchMode, chapterMode: $chapterMode, searchApiConfig: $searchApiConfig, chapterApiConfig: $chapterApiConfig, api: $api}';
  }
}

String _normalizeApiLevel(String? api) {
  final trimmed = api?.trim() ?? '';
  return trimmed.isEmpty ? RuleApiLevel.defaultApi : trimmed;
}

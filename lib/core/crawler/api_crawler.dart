import 'dart:convert';

import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/restricted_json_path.dart';
import 'package:anime_flow/core/crawler/rule_exceptions.dart';
import 'package:anime_flow/core/crawler/rule_template.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/utils.dart' show resolveSourceUrl;
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/search_resources_item.dart';

/// API 规则解析器：校验规则 + 用 JSONPath 解析响应。
///
/// 与 `HtmlCrawler` 对称——`HtmlCrawler` 负责 XPath 模式，本类负责 API 模式；
/// 请求模板渲染见 `RuleTemplate`，JSONPath 白名单见 `RestrictedJsonPath`。
/// 两者的出口都是 [SearchResourcesItem] / [CrawlerEpisodeResourcesItem]，
/// 因此下游的搜索排序、选集、播放解析无需感知模式差异。
class ApiCrawler {
  static LiggLogger logger = LiggLogger();

  // ---------------------------------------------------------------------------
  // 规则校验（编辑器保存前同样复用）
  // ---------------------------------------------------------------------------

  static void validateSearchConfig(ApiSearchConfig config) {
    RestrictedJsonPath.validate(config.listPath);
    RestrictedJsonPath.validate(config.namePath);
    RestrictedJsonPath.validate(config.sourcePath);
  }

  static void validateChapterConfig(ApiChapterConfig config) {
    for (final path in config.variables.values) {
      RestrictedJsonPath.validate(path);
    }

    if (config.format == ApiChapterFormat.delimited) {
      RestrictedJsonPath.validate(config.roadNamesPath);
      RestrictedJsonPath.validate(config.roadEpisodesPath);
      if (config.roadSeparator.isEmpty ||
          config.episodeSeparator.isEmpty ||
          config.fieldSeparator.isEmpty) {
        throw const ApiRuleFormatException('章节分隔符不能为空');
      }
      return;
    }

    if (config.roadsPath.trim().isNotEmpty) {
      RestrictedJsonPath.validate(config.roadsPath);
    }
    if (config.roadNamePath.trim().isNotEmpty) {
      RestrictedJsonPath.validate(config.roadNamePath);
    }
    RestrictedJsonPath.validate(config.episodesPath);
    RestrictedJsonPath.validate(config.episodeNamePath);

    if (config.episodeUrlPath.trim().isNotEmpty) {
      RestrictedJsonPath.validate(config.episodeUrlPath);
    } else if (config.episodePage == null) {
      throw const ApiRuleFormatException(
        '必须配置播放入口地址路径或播放页地址模板',
      );
    }

    if (config.episodePage != null && config.episodePage!.url.trim().isEmpty) {
      throw const ApiRuleFormatException('播放页地址模板不能为空');
    }
  }

  // ---------------------------------------------------------------------------
  // 响应解析
  // ---------------------------------------------------------------------------

  static List<SearchResourcesItem> parseSearch(
    String raw,
    ApiSearchConfig config,
  ) {
    validateSearchConfig(config);
    final document = _decodeResponse(raw);
    final nodes = RestrictedJsonPath.read(document, config.listPath);

    final items = <SearchResourcesItem>[];
    for (var index = 0; index < nodes.length; index++) {
      final node = nodes[index];
      try {
        final name =
            _stringValue(RestrictedJsonPath.readFirst(node, config.namePath));
        final source =
            _stringValue(RestrictedJsonPath.readFirst(node, config.sourcePath));
        if (name.isEmpty || source.isEmpty) {
          logger.w('ApiCrawler: 搜索节点 $index 缺少名称或链接，已跳过');
          continue;
        }
        items.add(SearchResourcesItem(name: name, link: source));
      } on ApiRuleFormatException {
        rethrow;
      } catch (error) {
        logger.w('ApiCrawler: 搜索节点 $index 解析失败：$error');
      }
    }
    return items;
  }

  static List<CrawlerEpisodeResourcesItem> parseChapters(
    String raw,
    ApiChapterConfig config, {
    required String source,
    required String baseUrl,
  }) {
    validateChapterConfig(config);
    final document = _decodeResponse(raw);

    final rootVariables = <String, Object?>{'source': source};
    for (final entry in config.variables.entries) {
      final value = RestrictedJsonPath.readFirst(document, entry.value);
      if (value == null) {
        throw ApiRuleFormatException(
          '章节响应变量 ${entry.key} 未匹配到值：${entry.value}',
        );
      }
      rootVariables[entry.key] = value;
    }

    return config.format == ApiChapterFormat.delimited
        ? _parseDelimited(document, config, rootVariables, baseUrl)
        : _parseNested(document, config, rootVariables, baseUrl);
  }

  static List<CrawlerEpisodeResourcesItem> _parseNested(
    dynamic document,
    ApiChapterConfig config,
    Map<String, Object?> rootVariables,
    String baseUrl,
  ) {
    final hasRoads = config.roadsPath.trim().isNotEmpty;
    final roadNodes = hasRoads
        ? RestrictedJsonPath.read(document, config.roadsPath)
        : <Object?>[document];

    final roads = <CrawlerEpisodeResourcesItem>[];
    for (var roadIndex = 0; roadIndex < roadNodes.length; roadIndex++) {
      final roadNode = roadNodes[roadIndex];
      try {
        final roadName = hasRoads && config.roadNamePath.trim().isNotEmpty
            ? _stringValue(
                RestrictedJsonPath.readFirst(roadNode, config.roadNamePath),
              )
            : '';

        final episodeNodes =
            RestrictedJsonPath.read(roadNode, config.episodesPath);
        final episodes = <Episode>[];
        for (var episodeIndex = 0;
            episodeIndex < episodeNodes.length;
            episodeIndex++) {
          try {
            final episodeNode = episodeNodes[episodeIndex];
            // `episodeNamePath` 仍然参与规则校验，但当前 Episode 模型
            // 只保存序号与地址，剧集名称暂时不消费。
            final rawUrl = config.episodeUrlPath.trim().isEmpty
                ? ''
                : _stringValue(
                    RestrictedJsonPath.readFirst(
                      episodeNode,
                      config.episodeUrlPath,
                    ),
                  );
            final pageUrl = _resolveEpisodeUrl(
              config,
              rootVariables,
              rawUrl: rawUrl,
              roadIndex: roadIndex,
              episodeIndex: episodeIndex,
              baseUrl: baseUrl,
            );
            if (pageUrl.isEmpty) {
              logger.w(
                'ApiCrawler: 线路 $roadIndex 的剧集节点 $episodeIndex 缺少 URL，已跳过',
              );
              continue;
            }
            episodes.add(
              Episode(episodeSort: episodeIndex + 1, like: pageUrl),
            );
          } on ApiRuleFormatException {
            rethrow;
          } catch (error) {
            logger.w(
              'ApiCrawler: 线路 $roadIndex 的剧集节点 $episodeIndex 解析失败：$error',
            );
          }
        }

        if (episodes.isEmpty) {
          logger.w('ApiCrawler: 线路节点 $roadIndex 没有有效剧集，已跳过');
          continue;
        }
        roads.add(
          CrawlerEpisodeResourcesItem(
            lineNames: roadName.isEmpty ? '播放线路${roads.length + 1}' : roadName,
            episodes: episodes,
          ),
        );
      } on ApiRuleFormatException {
        rethrow;
      } catch (error) {
        logger.w('ApiCrawler: 线路节点 $roadIndex 解析失败：$error');
      }
    }
    return roads;
  }

  static List<CrawlerEpisodeResourcesItem> _parseDelimited(
    dynamic document,
    ApiChapterConfig config,
    Map<String, Object?> rootVariables,
    String baseUrl,
  ) {
    final namesValue = _stringValue(
      RestrictedJsonPath.readFirst(document, config.roadNamesPath),
    );
    final episodesValue = _stringValue(
      RestrictedJsonPath.readFirst(document, config.roadEpisodesPath),
    );
    if (episodesValue.isEmpty) return <CrawlerEpisodeResourcesItem>[];

    final roadNames = namesValue.split(config.roadSeparator);
    final roadGroups = episodesValue.split(config.roadSeparator);

    final roads = <CrawlerEpisodeResourcesItem>[];
    for (var roadIndex = 0; roadIndex < roadGroups.length; roadIndex++) {
      final entries = roadGroups[roadIndex].split(config.episodeSeparator);
      final episodes = <Episode>[];

      for (var episodeIndex = 0;
          episodeIndex < entries.length;
          episodeIndex++) {
        final entry = entries[episodeIndex].trim();
        if (entry.isEmpty) continue;

        final separatorIndex = entry.indexOf(config.fieldSeparator);
        if (separatorIndex < 0) {
          logger.w(
            'ApiCrawler: 线路 $roadIndex 的剧集条目 $episodeIndex 缺少字段分隔符，已跳过',
          );
          continue;
        }
        final rawUrl = entry
            .substring(separatorIndex + config.fieldSeparator.length)
            .trim();

        try {
          final pageUrl = _resolveEpisodeUrl(
            config,
            rootVariables,
            rawUrl: rawUrl,
            roadIndex: roadIndex,
            episodeIndex: episodeIndex,
            baseUrl: baseUrl,
          );
          if (pageUrl.isEmpty) {
            logger.w(
              'ApiCrawler: 线路 $roadIndex 的剧集条目 $episodeIndex 缺少 URL，已跳过',
            );
            continue;
          }
          episodes.add(Episode(episodeSort: episodeIndex + 1, like: pageUrl));
        } on ApiRuleFormatException {
          rethrow;
        } catch (error) {
          logger.w(
            'ApiCrawler: 线路 $roadIndex 的剧集条目 $episodeIndex 解析失败：$error',
          );
        }
      }

      if (episodes.isEmpty) {
        logger.w('ApiCrawler: 线路 $roadIndex 没有有效剧集，已跳过');
        continue;
      }
      final configuredName =
          roadIndex < roadNames.length ? roadNames[roadIndex].trim() : '';
      roads.add(
        CrawlerEpisodeResourcesItem(
          lineNames: configuredName.isEmpty
              ? '播放线路${roads.length + 1}'
              : configuredName,
          episodes: episodes,
        ),
      );
    }
    return roads;
  }

  /// 生成最终播放页地址。
  ///
  /// 未配置 [ApiChapterConfig.episodePage] 时直接归一化响应里的地址；
  /// 配置了模板时，用 `@episodeUrl` 与 0/1-based 的线路/剧集索引渲染模板
  /// （模板语言没有算术，因此两套索引都需要提供）。
  static String _resolveEpisodeUrl(
    ApiChapterConfig config,
    Map<String, Object?> rootVariables, {
    required String rawUrl,
    required int roadIndex,
    required int episodeIndex,
    required String baseUrl,
  }) {
    final page = config.episodePage;
    if (page == null) return _resolveUrl(baseUrl, rawUrl);
    if (page.url.trim().isEmpty) {
      throw const ApiRuleFormatException('播放页地址模板不能为空');
    }

    final variables = <String, Object?>{
      ...rootVariables,
      'episodeUrl': rawUrl,
      'roadIndex': roadIndex,
      'roadNumber': roadIndex + 1,
      'episodeIndex': episodeIndex,
      'episodeNumber': episodeIndex + 1,
    };
    final path = RuleTemplate.render(page.url, variables, encode: true);
    final uri = Uri.tryParse(path);
    if (uri == null) {
      throw ApiRuleFormatException('剧集页面 URL 无效：$path');
    }

    final renderedQuery = RuleTemplate.renderMap(page.query, variables).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final mergedQuery = <String, String>{
      ...uri.queryParameters,
      ...renderedQuery,
    };
    // 空 map 交给 Uri.replace 会留下一个多余的 "?"，
    // 生成与规范地址不同的字符串，导致播放身份 key 不一致。
    final pageUri =
        mergedQuery.isEmpty ? uri : uri.replace(queryParameters: mergedQuery);
    return _resolveUrl(baseUrl, pageUri.toString());
  }

  /// 基于 [baseUrl] 归一化地址；[baseUrl] 缺失或非法时退化为原值去空白。
  static String _resolveUrl(String baseUrl, String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final base = Uri.tryParse(baseUrl.trim());
    if (base == null || !base.hasScheme || base.host.isEmpty) {
      return trimmed;
    }
    try {
      return resolveSourceUrl(baseUrl, trimmed);
    } catch (_) {
      return trimmed;
    }
  }

  static dynamic _decodeResponse(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException catch (error) {
      throw ApiRuleFormatException('API 响应不是有效 JSON：${error.message}');
    }
  }

  static String _stringValue(Object? value) {
    if (value == null) return '';
    return value is String ? value.trim() : value.toString().trim();
  }
}

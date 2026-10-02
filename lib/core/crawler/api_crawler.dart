import 'dart:convert';

import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/utils/utils.dart' show resolveSourceUrl;
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/search_resources_item.dart';
import 'package:json_path/json_path.dart';

/// API 规则在准备请求或解析响应时出现的问题。
class ApiRuleFormatException implements Exception {
  const ApiRuleFormatException(this.message);

  final String message;

  @override
  String toString() => 'ApiRuleFormatException: $message';
}

/// 受限 JSONPath。
///
/// 规则文件由第三方提供，**不能**把任意表达式直接交给 JSONPath 求值。
/// 这里只放行最基础、最常见的语法，其余（函数、过滤器、递归 `..`、联合等）
/// 一律拒绝，校验通过后再交给 `json_path` 解析。
class RestrictedJsonPath {
  const RestrictedJsonPath._();

  static void validate(String expression) {
    if (expression.isEmpty || !expression.startsWith(r'$')) {
      throw ApiRuleFormatException('JSONPath 必须以 \$ 开头：$expression');
    }

    var index = 1;
    while (index < expression.length) {
      final char = expression[index];

      if (char == '.') {
        index++;
        final start = index;
        while (index < expression.length &&
            RegExp(r'[A-Za-z0-9_$-]').hasMatch(expression[index])) {
          index++;
        }
        if (index == start) {
          throw ApiRuleFormatException('不支持的 JSONPath：$expression');
        }
        continue;
      }

      if (char == '[') {
        final end = _findBracketEnd(expression, index);
        final content = expression.substring(index + 1, end).trim();
        final isIndex = RegExp(r'^\d+$').hasMatch(content);
        final isWildcard = content == '*';
        final isQuoted = content.length >= 2 &&
            ((content.startsWith("'") && content.endsWith("'")) ||
                (content.startsWith('"') && content.endsWith('"')));
        if (!isIndex && !isWildcard && !isQuoted) {
          throw ApiRuleFormatException('不支持的 JSONPath 片段：[$content]');
        }
        index = end + 1;
        continue;
      }

      throw ApiRuleFormatException('不支持的 JSONPath：$expression');
    }
  }

  static int _findBracketEnd(String expression, int start) {
    String? quote;
    var escaped = false;
    for (var i = start + 1; i < expression.length; i++) {
      final char = expression[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == '\\') {
        escaped = true;
        continue;
      }
      if (quote != null) {
        if (char == quote) quote = null;
        continue;
      }
      if (char == "'" || char == '"') {
        quote = char;
        continue;
      }
      if (char == ']') return i;
    }
    throw ApiRuleFormatException('JSONPath 缺少 ]：$expression');
  }

  static List<Object?> read(dynamic document, String expression) {
    validate(expression);
    try {
      return JsonPath(expression).readValues(document).toList();
    } catch (error) {
      throw ApiRuleFormatException('JSONPath 解析失败 $expression：$error');
    }
  }

  static Object? readFirst(dynamic document, String expression) {
    final values = read(document, expression);
    return values.isEmpty ? null : values.first;
  }
}

/// API 规则解析器：请求模板渲染 + JSONPath 响应解析。
///
/// 与 [HtmlCrawler] 对称——`HtmlCrawler` 负责 XPath 模式，本类负责 API 模式，
/// 两者的出口都是 [SearchResourcesItem] / [CrawlerEpisodeResourcesItem]，
/// 因此下游的搜索排序、选集、播放解析无需感知模式差异。
class ApiCrawler {
  static LiggLogger logger = LiggLogger();

  /// `@name` 形式的内联变量。
  static final RegExp _atVariable =
      RegExp(r'(?<![A-Za-z0-9_])@([A-Za-z_][A-Za-z0-9_]*)');

  /// `{name}` 形式的兼容变量（XPath 规则的搜索链接使用该写法）。
  static final RegExp _braceVariable = RegExp(r'\{([A-Za-z_][A-Za-z0-9_]*)\}');

  /// 整个字符串就是一个 `@name`，此时保留变量原始类型。
  static final RegExp _exactVariable = RegExp(r'^@([A-Za-z_][A-Za-z0-9_]*)$');

  // ---------------------------------------------------------------------------
  // 模板渲染
  // ---------------------------------------------------------------------------

  static String renderTemplate(
    String template,
    Map<String, Object?> variables, {
    bool encode = false,
  }) {
    if (template.isEmpty) return template;
    final withAt = template.replaceAllMapped(
      _atVariable,
      (match) => _renderVariable(match.group(1)!, variables, encode: encode),
    );
    return withAt.replaceAllMapped(
      _braceVariable,
      (match) => _renderVariable(match.group(1)!, variables, encode: encode),
    );
  }

  static Map<String, dynamic> renderMap(
    Map<String, dynamic> input,
    Map<String, Object?> variables,
  ) {
    return input.map(
      (key, value) => MapEntry(
        renderTemplate(key, variables),
        renderValue(value, variables),
      ),
    );
  }

  static dynamic renderValue(
    dynamic value,
    Map<String, Object?> variables,
  ) {
    if (value is String) {
      final exact = _exactVariable.firstMatch(value.trim());
      if (exact != null) {
        final name = exact.group(1)!;
        if (!variables.containsKey(name)) {
          throw ApiRuleFormatException('缺少模板变量 @$name');
        }
        return variables[name];
      }
      return renderTemplate(value, variables);
    }
    if (value is List) {
      return value.map((item) => renderValue(item, variables)).toList();
    }
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          renderValue(item, variables),
        ),
      );
    }
    return value;
  }

  static String _renderVariable(
    String name,
    Map<String, Object?> variables, {
    required bool encode,
  }) {
    if (!variables.containsKey(name)) {
      throw ApiRuleFormatException('缺少模板变量 @$name');
    }
    final value = variables[name]?.toString() ?? '';
    return encode ? Uri.encodeComponent(value) : value;
  }

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
    final path = renderTemplate(page.url, variables, encode: true);
    final uri = Uri.tryParse(path);
    if (uri == null) {
      throw ApiRuleFormatException('剧集页面 URL 无效：$path');
    }

    final renderedQuery = renderMap(page.query, variables).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final mergedQuery = <String, String>{
      ...uri.queryParameters,
      ...renderedQuery,
    };
    return _resolveUrl(
        baseUrl, uri.replace(queryParameters: mergedQuery).toString());
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

/// 渲染含 `{keyword}` 占位符的页面地址模板（验证页等场景使用）。
///
/// `@变量` 是 API 请求模板的语法，由 [ApiCrawler.renderTemplate] 处理；
/// 这里只负责规则里已有的 `{keyword}` 写法，替换值做 URL 编码。
String renderKeywordUrl(String template, String keyword) {
  return template.replaceAll('{keyword}', Uri.encodeQueryComponent(keyword));
}

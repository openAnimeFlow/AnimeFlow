import 'package:hive_ce/hive.dart';

part 'api_rule_config.g.dart';

/// 规则解析模式。
///
/// - [xpath]：请求 HTML 页面，用 XPath 解析（现有模式）
/// - [api]：请求接口，用 JSONPath 解析响应
///
/// 搜索与章节可以分别选择模式，互不影响。
class RuleMode {
  static const String xpath = 'xpath';
  static const String api = 'api';

  /// 缺省或非法值一律回退到 [xpath]，保证老规则行为不变。
  static String normalize(Object? value) => value == api ? api : xpath;
}

/// API 请求体类型。
class ApiBodyType {
  static const String none = 'none';
  static const String json = 'json';
  static const String form = 'form';

  static String normalize(Object? value) => switch (value) {
        json => json,
        form => form,
        _ => none,
      };
}

/// API 章节响应的解析格式。
///
/// - [nested]：线路与剧集为嵌套结构
/// - [delimited]：线路与剧集为带分隔符的字符串
class ApiChapterFormat {
  static const String nested = 'nested';
  static const String delimited = 'delimited';

  static String normalize(Object? value) =>
      value == delimited ? delimited : nested;
}

/// API 请求模板：URL / 查询参数 / 请求头 / 请求体均支持 `@变量` 模板。
@HiveType(typeId: 14)
class ApiRequestConfig {
  /// 仅支持 GET / POST，构造时统一转大写。
  @HiveField(0)
  String method;

  @HiveField(1)
  String url;

  @HiveField(2)
  Map<String, dynamic> headers;

  @HiveField(3)
  Map<String, dynamic> query;

  /// 见 [ApiBodyType]。
  @HiveField(4)
  String bodyType;

  /// 仅 [bodyType] 非 [ApiBodyType.none] 时生效。
  @HiveField(5)
  dynamic body;

  ApiRequestConfig({
    String? method,
    String? url,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? query,
    String? bodyType,
    this.body,
  })  : method = (method ?? 'GET').toUpperCase(),
        url = url ?? '',
        headers = headers ?? <String, dynamic>{},
        query = query ?? <String, dynamic>{},
        bodyType = ApiBodyType.normalize(bodyType);

  factory ApiRequestConfig.fromJson(Map<String, dynamic> json) {
    return ApiRequestConfig(
      method: json['method']?.toString(),
      url: json['url']?.toString(),
      headers: _asStringMap(json['headers']),
      query: _asStringMap(json['query']),
      bodyType: json['bodyType']?.toString(),
      body: json['body'],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'method': method.toUpperCase(),
        'url': url,
        if (headers.isNotEmpty) 'headers': headers,
        if (query.isNotEmpty) 'query': query,
        if (bodyType != ApiBodyType.none) 'bodyType': bodyType,
        if (bodyType != ApiBodyType.none && body != null) 'body': body,
      };
}

/// API 搜索规则：请求配置 + 搜索结果的 JSONPath 映射。
@HiveType(typeId: 15)
class ApiSearchConfig {
  @HiveField(0)
  ApiRequestConfig request;

  /// 搜索结果列表，默认 `$.data[*]`。
  @HiveField(1)
  String listPath;

  /// 条目名称，默认 `$.name`。
  @HiveField(2)
  String namePath;

  /// 条目链接，默认 `$.url`。
  @HiveField(3)
  String sourcePath;

  ApiSearchConfig({
    ApiRequestConfig? request,
    String? listPath,
    String? namePath,
    String? sourcePath,
  })  : request = request ?? ApiRequestConfig(),
        listPath = listPath ?? r'$.data[*]',
        namePath = namePath ?? r'$.name',
        sourcePath = sourcePath ?? r'$.url';

  factory ApiSearchConfig.fromJson(Map<String, dynamic> json) {
    return ApiSearchConfig(
      request: ApiRequestConfig.fromJson(_asStringMap(json['request'])),
      listPath: json['listPath']?.toString(),
      namePath: json['namePath']?.toString(),
      sourcePath: json['sourcePath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'request': request.toJson(),
        'listPath': listPath,
        'namePath': namePath,
        'sourcePath': sourcePath,
      };
}

/// 可选的播放页地址模板。
///
/// 当章节响应里没有可直接使用的播放页 URL 时，用该模板配合
/// `@episodeUrl` / `@episodeIndex` / `@episodeNumber` 等变量生成。
@HiveType(typeId: 16)
class ApiEpisodePageConfig {
  @HiveField(0)
  String url;

  @HiveField(1)
  Map<String, dynamic> query;

  ApiEpisodePageConfig({
    String? url,
    Map<String, dynamic>? query,
  })  : url = url ?? '',
        query = query ?? <String, dynamic>{};

  factory ApiEpisodePageConfig.fromJson(Map<String, dynamic> json) {
    return ApiEpisodePageConfig(
      url: json['url']?.toString(),
      query: _asStringMap(json['query']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
        'query': query,
      };
}

/// API 章节规则：请求配置 + 响应映射。
@HiveType(typeId: 17)
class ApiChapterConfig {
  @HiveField(0)
  ApiRequestConfig request;

  /// 见 [ApiChapterFormat]。
  @HiveField(1)
  String format;

  // ---- nested 格式 ----

  /// 线路列表，默认 `$.data.roads[*]`；留空表示响应根节点即单条线路。
  @HiveField(2)
  String roadsPath;

  /// 线路名称，默认 `$.name`。
  @HiveField(3)
  String roadNamePath;

  /// 剧集列表，默认 `$.episodes[*]`。
  @HiveField(4)
  String episodesPath;

  /// 剧集名称，默认 `$.name`。
  @HiveField(5)
  String episodeNamePath;

  /// 剧集播放页地址，默认 `$.url`；留空时由 [episodePage] 生成。
  @HiveField(6)
  String episodeUrlPath;

  // ---- delimited 格式 ----

  @HiveField(7)
  String roadNamesPath;

  @HiveField(8)
  String roadEpisodesPath;

  /// 线路之间的分隔符，默认 `$$$`。
  @HiveField(9)
  String roadSeparator;

  /// 剧集之间的分隔符，默认 `#`。
  @HiveField(10)
  String episodeSeparator;

  /// 名称与地址之间的分隔符，默认 `$`。
  @HiveField(11)
  String fieldSeparator;

  /// 命名 JSONPath 捕获，作为模板变量暴露给 [episodePage]。
  @HiveField(12)
  Map<String, String> variables;

  /// 可选播放页模板。
  @HiveField(13)
  ApiEpisodePageConfig? episodePage;

  ApiChapterConfig({
    ApiRequestConfig? request,
    String? format,
    String? roadsPath,
    String? roadNamePath,
    String? episodesPath,
    String? episodeNamePath,
    String? episodeUrlPath,
    String? roadNamesPath,
    String? roadEpisodesPath,
    String? roadSeparator,
    String? episodeSeparator,
    String? fieldSeparator,
    Map<String, String>? variables,
    this.episodePage,
  })  : request = request ?? ApiRequestConfig(),
        format = ApiChapterFormat.normalize(format),
        roadsPath = roadsPath ?? r'$.data.roads[*]',
        roadNamePath = roadNamePath ?? r'$.name',
        episodesPath = episodesPath ?? r'$.episodes[*]',
        episodeNamePath = episodeNamePath ?? r'$.name',
        episodeUrlPath = episodeUrlPath ?? r'$.url',
        roadNamesPath = roadNamesPath ?? '',
        roadEpisodesPath = roadEpisodesPath ?? '',
        roadSeparator = roadSeparator ?? r'$$$',
        episodeSeparator = episodeSeparator ?? '#',
        fieldSeparator = fieldSeparator ?? r'$',
        variables = variables ?? <String, String>{};

  factory ApiChapterConfig.fromJson(Map<String, dynamic> json) {
    final rawVariables = _asStringMap(json['variables']);
    return ApiChapterConfig(
      request: ApiRequestConfig.fromJson(_asStringMap(json['request'])),
      format: json['format']?.toString(),
      roadsPath: json['roadsPath']?.toString(),
      roadNamePath: json['roadNamePath']?.toString(),
      episodesPath: json['episodesPath']?.toString(),
      episodeNamePath: json['episodeNamePath']?.toString(),
      episodeUrlPath: json['episodeUrlPath']?.toString(),
      roadNamesPath: json['roadNamesPath']?.toString(),
      roadEpisodesPath: json['roadEpisodesPath']?.toString(),
      roadSeparator: json['roadSeparator']?.toString(),
      episodeSeparator: json['episodeSeparator']?.toString(),
      fieldSeparator: json['fieldSeparator']?.toString(),
      variables: rawVariables.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      episodePage: json['episodePage'] is Map
          ? ApiEpisodePageConfig.fromJson(
              _asStringMap(json['episodePage']),
            )
          : null,
    );
  }

  /// [nested] 侧是否存在非默认配置。
  ///
  /// 持久化会重写整份规则列表，切换格式后另一侧的配置也必须保留。
  bool get _hasNestedConfig =>
      roadsPath != r'$.data.roads[*]' ||
      roadNamePath != r'$.name' ||
      episodesPath != r'$.episodes[*]' ||
      episodeNamePath != r'$.name' ||
      episodeUrlPath != r'$.url';

  bool get _hasDelimitedConfig =>
      roadNamesPath.isNotEmpty || roadEpisodesPath.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'request': request.toJson(),
        'format': format,
        if (format == ApiChapterFormat.nested || _hasNestedConfig) ...{
          'roadsPath': roadsPath,
          'roadNamePath': roadNamePath,
          'episodesPath': episodesPath,
          'episodeNamePath': episodeNamePath,
          'episodeUrlPath': episodeUrlPath,
        },
        if (format == ApiChapterFormat.delimited || _hasDelimitedConfig) ...{
          'roadNamesPath': roadNamesPath,
          'roadEpisodesPath': roadEpisodesPath,
          'roadSeparator': roadSeparator,
          'episodeSeparator': episodeSeparator,
          'fieldSeparator': fieldSeparator,
        },
        if (variables.isNotEmpty) 'variables': variables,
        if (episodePage != null) 'episodePage': episodePage!.toJson(),
      };
}

Map<String, dynamic> _asStringMap(Object? value) {
  if (value is! Map) return <String, dynamic>{};
  return value.map((key, value) => MapEntry(key.toString(), value));
}

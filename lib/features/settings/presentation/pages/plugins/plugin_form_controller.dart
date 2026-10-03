import 'dart:convert';

import 'package:anime_flow/core/crawler/item/anti_crawler_config.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:flutter/widgets.dart';

/// 规则编辑器里 XPath 字段在 [PluginFormController.xpathControllers] 中的下标。
class PluginFormIndex {
  const PluginFormIndex._();

  static const int version = 0;
  static const int name = 1;
  static const int icon = 2;
  static const int baseUrl = 3;
  static const int searchUrl = 4;
  static const int searchList = 5;
  static const int searchName = 6;
  static const int searchLink = 7;
  static const int lineNames = 8;
  static const int lineList = 9;
  static const int episode = 10;

  static const int count = 11;

  static const List<int> basic = [version, name, icon, baseUrl];

  static const List<int> xpathSearch = [
    searchUrl,
    searchList,
    searchName,
    searchLink,
  ];

  static const List<int> xpathChapter = [lineNames, lineList, episode];
}

/// API 请求字段的输入控制器集合（搜索与章节各一份）。
class ApiRequestControllers {
  String method = 'GET';
  String bodyType = ApiBodyType.none;
  final TextEditingController url = TextEditingController();
  final TextEditingController headers = TextEditingController();
  final TextEditingController query = TextEditingController();
  final TextEditingController body = TextEditingController();
}

/// 规则编辑器的输入状态、校验与规则构建。
///
/// 页面只负责渲染这里的状态、在变更后重建，并调用 [build] 取回
/// [CrawlConfigItem]；所有控制器、模式开关与校验规则都收敛在本类里。
class PluginFormController {
  PluginFormController() {
    // 新建规则时用 schema 默认值预填 API 配置，便于直接照着改。
    _applySearchApiConfig(ApiSearchConfig());
    _applyChapterApiConfig(ApiChapterConfig());
    _attachListeners();
  }

  /// 任何输入变化后回调，页面用它触发重建。
  VoidCallback? onChanged;

  // ---------------------------------------------------------------------------
  // 输入状态
  // ---------------------------------------------------------------------------

  final List<TextEditingController> xpathControllers =
      List.generate(PluginFormIndex.count, (_) => TextEditingController());

  String searchMode = RuleMode.xpath;
  String chapterMode = RuleMode.xpath;

  // ---- 反爬 ----
  bool antiEnabled = false;
  int captchaType = CaptchaType.imageCaptcha;
  int captchaDetectType = CaptchaDetectType.xpath;

  /// 预留字段：自定义 JS 验证脚本，暂无控件与执行逻辑，保存时原样保留。
  String captchaScript = '';

  final TextEditingController captchaImage = TextEditingController();
  final TextEditingController captchaInput = TextEditingController();
  final TextEditingController captchaButton = TextEditingController();
  final TextEditingController captchaDetectValue = TextEditingController();
  final TextEditingController captchaPageUrl = TextEditingController();

  // ---- API 搜索 ----
  final ApiRequestControllers searchRequest = ApiRequestControllers();
  final TextEditingController apiListPath = TextEditingController();
  final TextEditingController apiNamePath = TextEditingController();
  final TextEditingController apiSourcePath = TextEditingController();

  // ---- API 章节 ----
  final ApiRequestControllers chapterRequest = ApiRequestControllers();
  String chapterFormat = ApiChapterFormat.nested;
  final TextEditingController apiRoadsPath = TextEditingController();
  final TextEditingController apiRoadNamePath = TextEditingController();
  final TextEditingController apiEpisodesPath = TextEditingController();
  final TextEditingController apiEpisodeNamePath = TextEditingController();
  final TextEditingController apiEpisodeUrlPath = TextEditingController();
  final TextEditingController apiRoadNamesPath = TextEditingController();
  final TextEditingController apiRoadEpisodesPath = TextEditingController();
  final TextEditingController apiRoadSeparator = TextEditingController();
  final TextEditingController apiEpisodeSeparator = TextEditingController();
  final TextEditingController apiFieldSeparator = TextEditingController();
  final TextEditingController apiVariables = TextEditingController();
  bool episodePageEnabled = false;
  final TextEditingController episodePageUrl = TextEditingController();
  final TextEditingController episodePageQuery = TextEditingController();

  // ---------------------------------------------------------------------------
  // 校验错误（键名与渲染层约定）
  // ---------------------------------------------------------------------------

  final Set<int> xpathErrors = {};
  final Set<String> apiErrors = {};
  final Set<String> antiErrors = {};

  bool get hasErrors =>
      xpathErrors.isNotEmpty || apiErrors.isNotEmpty || antiErrors.isNotEmpty;

  /// JSON 类字段的错误键前缀，渲染层据此区分「必填」与「格式错误」。
  static const String jsonErrorPrefix = 'json:';

  // ---------------------------------------------------------------------------
  // 模式与选项切换
  // ---------------------------------------------------------------------------

  void setSearchMode(String value) {
    if (searchMode == value) return;
    searchMode = value;
    _notify();
  }

  void setChapterMode(String value) {
    if (chapterMode == value) return;
    chapterMode = value;
    _notify();
  }

  void setChapterFormat(String value) {
    if (chapterFormat == value) return;
    chapterFormat = value;
    _notify();
  }

  void setAntiEnabled(bool value) {
    if (antiEnabled == value) return;
    antiEnabled = value;
    _notify();
  }

  void setCaptchaType(int value) {
    if (captchaType == value) return;
    captchaType = value;
    _notify();
  }

  void setCaptchaDetectType(int value) {
    if (captchaDetectType == value) return;
    captchaDetectType = value;
    _notify();
  }

  void setEpisodePageEnabled(bool value) {
    if (episodePageEnabled == value) return;
    episodePageEnabled = value;
    _notify();
  }

  void setRequestMethod(ApiRequestControllers target, String value) {
    if (target.method == value) return;
    target.method = value;
    _notify();
  }

  void setRequestMethodByFlag({required bool isSearch, required String value}) {
    setRequestMethod(isSearch ? searchRequest : chapterRequest, value);
  }

  void setRequestBodyType(ApiRequestControllers target, String value) {
    if (target.bodyType == value) return;
    target.bodyType = value;
    _notify();
  }

  void setRequestBodyTypeByFlag({
    required bool isSearch,
    required String value,
  }) {
    setRequestBodyType(isSearch ? searchRequest : chapterRequest, value);
  }

  // ---------------------------------------------------------------------------
  // 装载已有规则
  // ---------------------------------------------------------------------------

  /// 把规则内容填进表单，并清空校验状态。
  void loadFrom(CrawlConfigItem config) {
    searchMode = config.searchMode;
    chapterMode = config.chapterMode;

    xpathControllers[PluginFormIndex.version].text = config.version;
    xpathControllers[PluginFormIndex.name].text = config.name;
    xpathControllers[PluginFormIndex.icon].text = config.iconUrl;
    xpathControllers[PluginFormIndex.baseUrl].text = config.baseUrl;
    xpathControllers[PluginFormIndex.searchUrl].text = config.searchUrl;
    xpathControllers[PluginFormIndex.searchList].text = config.searchList;
    xpathControllers[PluginFormIndex.searchName].text = config.searchName;
    xpathControllers[PluginFormIndex.searchLink].text = config.searchLink;
    xpathControllers[PluginFormIndex.lineNames].text = config.lineNames;
    xpathControllers[PluginFormIndex.lineList].text = config.lineList;
    xpathControllers[PluginFormIndex.episode].text = config.episode;

    _applyAntiCrawlerConfig(config.antiCrawlerConfig);
    _applySearchApiConfig(config.searchApiConfig);
    _applyChapterApiConfig(config.chapterApiConfig);

    clearErrors();
  }

  void _applyAntiCrawlerConfig(AntiCrawlerConfig anti) {
    antiEnabled = anti.enabled;
    captchaType = anti.captchaType;
    captchaDetectType = anti.captchaDetectType;
    captchaImage.text = anti.captchaImage;
    captchaInput.text = anti.captchaInput;
    captchaButton.text = anti.captchaButton;
    captchaDetectValue.text = anti.captchaDetectValue;
    captchaPageUrl.text = anti.captchaPageUrl;
    captchaScript = anti.captchaScript;
  }

  void _applySearchApiConfig(ApiSearchConfig config) {
    _applyApiRequest(searchRequest, config.request);
    apiListPath.text = config.listPath;
    apiNamePath.text = config.namePath;
    apiSourcePath.text = config.sourcePath;
  }

  void _applyChapterApiConfig(ApiChapterConfig config) {
    _applyApiRequest(chapterRequest, config.request);
    chapterFormat = config.format;
    apiRoadsPath.text = config.roadsPath;
    apiRoadNamePath.text = config.roadNamePath;
    apiEpisodesPath.text = config.episodesPath;
    apiEpisodeNamePath.text = config.episodeNamePath;
    apiEpisodeUrlPath.text = config.episodeUrlPath;
    apiRoadNamesPath.text = config.roadNamesPath;
    apiRoadEpisodesPath.text = config.roadEpisodesPath;
    apiRoadSeparator.text = config.roadSeparator;
    apiEpisodeSeparator.text = config.episodeSeparator;
    apiFieldSeparator.text = config.fieldSeparator;
    apiVariables.text = _encodeJson(config.variables);

    final page = config.episodePage;
    episodePageEnabled = page != null;
    episodePageUrl.text = page?.url ?? '';
    episodePageQuery.text = _encodeJson(page?.query);
  }

  void _applyApiRequest(
    ApiRequestControllers target,
    ApiRequestConfig request,
  ) {
    target.method = request.method;
    target.bodyType = request.bodyType;
    target.url.text = request.url;
    target.headers.text = _encodeJson(request.headers);
    target.query.text = _encodeJson(request.query);
    target.body.text = _encodeJson(request.body);
  }

  static String _encodeJson(Object? value) {
    if (value == null) return '';
    if (value is Map && value.isEmpty) return '';
    if (value is Iterable && value.isEmpty) return '';
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  // ---------------------------------------------------------------------------
  // 构建规则
  // ---------------------------------------------------------------------------

  /// 用当前表单内容构建规则；JSON 字段非法时会抛出 [FormatException]。
  CrawlConfigItem build({required String api}) {
    return CrawlConfigItem(
      version: xpathControllers[PluginFormIndex.version].text.trim(),
      name: xpathControllers[PluginFormIndex.name].text.trim(),
      iconUrl: xpathControllers[PluginFormIndex.icon].text.trim(),
      baseUrl: xpathControllers[PluginFormIndex.baseUrl].text.trim(),
      searchUrl: xpathControllers[PluginFormIndex.searchUrl].text.trim(),
      searchList: xpathControllers[PluginFormIndex.searchList].text.trim(),
      searchName: xpathControllers[PluginFormIndex.searchName].text.trim(),
      searchLink: xpathControllers[PluginFormIndex.searchLink].text.trim(),
      lineNames: xpathControllers[PluginFormIndex.lineNames].text.trim(),
      lineList: xpathControllers[PluginFormIndex.lineList].text.trim(),
      episode: xpathControllers[PluginFormIndex.episode].text.trim(),
      antiCrawlerConfig: _buildAntiCrawlerConfig(),
      searchMode: searchMode,
      chapterMode: chapterMode,
      searchApiConfig: _buildSearchApiConfig(),
      chapterApiConfig: _buildChapterApiConfig(),
      api: api,
    );
  }

  AntiCrawlerConfig _buildAntiCrawlerConfig() {
    return AntiCrawlerConfig(
      enabled: antiEnabled,
      captchaType: captchaType,
      captchaImage: captchaImage.text.trim(),
      captchaInput: captchaInput.text.trim(),
      captchaButton: captchaButton.text.trim(),
      captchaDetectType: captchaDetectType,
      captchaDetectValue: captchaDetectValue.text.trim(),
      captchaPageUrl: captchaPageUrl.text.trim(),
      captchaScript: captchaScript,
    );
  }

  ApiSearchConfig _buildSearchApiConfig() {
    return ApiSearchConfig(
      request: _buildApiRequest(searchRequest),
      listPath: apiListPath.text.trim(),
      namePath: apiNamePath.text.trim(),
      sourcePath: apiSourcePath.text.trim(),
    );
  }

  ApiChapterConfig _buildChapterApiConfig() {
    final variables = decodeJsonMap(apiVariables);
    return ApiChapterConfig(
      request: _buildApiRequest(chapterRequest),
      format: chapterFormat,
      roadsPath: apiRoadsPath.text.trim(),
      roadNamePath: apiRoadNamePath.text.trim(),
      episodesPath: apiEpisodesPath.text.trim(),
      episodeNamePath: apiEpisodeNamePath.text.trim(),
      episodeUrlPath: apiEpisodeUrlPath.text.trim(),
      roadNamesPath: apiRoadNamesPath.text.trim(),
      roadEpisodesPath: apiRoadEpisodesPath.text.trim(),
      roadSeparator: apiRoadSeparator.text.trim(),
      episodeSeparator: apiEpisodeSeparator.text.trim(),
      fieldSeparator: apiFieldSeparator.text.trim(),
      variables: variables.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      episodePage: episodePageEnabled
          ? ApiEpisodePageConfig(
              url: episodePageUrl.text.trim(),
              query: decodeJsonMap(episodePageQuery),
            )
          : null,
    );
  }

  ApiRequestConfig _buildApiRequest(ApiRequestControllers source) {
    return ApiRequestConfig(
      method: source.method,
      url: source.url.text.trim(),
      headers: decodeJsonMap(source.headers),
      query: decodeJsonMap(source.query),
      bodyType: source.bodyType,
      body: source.bodyType == ApiBodyType.none
          ? null
          : decodeJsonValue(source.body),
    );
  }

  static Map<String, dynamic> decodeJsonMap(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('JSON 必须是对象');
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  static dynamic decodeJsonValue(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return jsonDecode(text);
  }

  void clearErrors() {
    xpathErrors.clear();
    apiErrors.clear();
    antiErrors.clear();
  }

  // ---------------------------------------------------------------------------
  // 监听与释放
  // ---------------------------------------------------------------------------

  void _attachListeners() {
    for (var index = 0; index < xpathControllers.length; index++) {
      final fieldIndex = index;
      xpathControllers[fieldIndex].addListener(() {
        if (xpathErrors.contains(fieldIndex) &&
            xpathControllers[fieldIndex].text.trim().isNotEmpty) {
          xpathErrors.remove(fieldIndex);
          _notify();
        }
      });
    }

    // API / 反爬字段的校验错误在任意编辑后统一清除，避免整片飘红。
    for (final controller in apiTextControllers()) {
      controller.addListener(() {
        if (apiErrors.isNotEmpty) {
          apiErrors.clear();
          _notify();
        }
      });
    }
    for (final controller in antiTextControllers()) {
      controller.addListener(() {
        if (antiErrors.isNotEmpty) {
          antiErrors.clear();
          _notify();
        }
      });
    }
  }

  List<TextEditingController> apiTextControllers() => [
        searchRequest.url,
        searchRequest.headers,
        searchRequest.query,
        searchRequest.body,
        apiListPath,
        apiNamePath,
        apiSourcePath,
        chapterRequest.url,
        chapterRequest.headers,
        chapterRequest.query,
        chapterRequest.body,
        apiRoadsPath,
        apiRoadNamePath,
        apiEpisodesPath,
        apiEpisodeNamePath,
        apiEpisodeUrlPath,
        apiRoadNamesPath,
        apiRoadEpisodesPath,
        apiRoadSeparator,
        apiEpisodeSeparator,
        apiFieldSeparator,
        apiVariables,
        episodePageUrl,
        episodePageQuery,
      ];

  List<TextEditingController> antiTextControllers() => [
        captchaImage,
        captchaInput,
        captchaButton,
        captchaDetectValue,
        captchaPageUrl,
      ];

  void _notify() => onChanged?.call();

  void dispose() {
    for (final controller in xpathControllers) {
      controller.dispose();
    }
    // apiTextControllers 已包含两份请求控制器，不要再单独释放。
    for (final controller in apiTextControllers()) {
      controller.dispose();
    }
    for (final controller in antiTextControllers()) {
      controller.dispose();
    }
  }
}

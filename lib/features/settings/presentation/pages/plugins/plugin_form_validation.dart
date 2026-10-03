import 'dart:convert';

import 'package:anime_flow/core/crawler/item/anti_crawler_config.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:flutter/widgets.dart';

import 'plugin_form_controller.dart';

/// 表单校验：只校验当前启用模式所需的字段，并把问题写进 controller 的错误集合。
///
/// 单独成文件是因为校验规则会随 schema 增长，与「输入状态 + 规则构建」是两件事。
extension PluginFormValidation on PluginFormController {
  /// 校验当前启用模式所需的字段，返回是否可以保存。
  bool validate() {
    clearErrors();

    _requireXPath(PluginFormIndex.basic);
    if (searchMode == RuleMode.xpath) {
      _requireXPath(PluginFormIndex.xpathSearch);
    } else {
      _validateApiSearch();
    }
    if (chapterMode == RuleMode.xpath) {
      _requireXPath(PluginFormIndex.xpathChapter);
    } else {
      _validateApiChapter();
    }
    if (antiEnabled) {
      _validateAntiCrawler();
    }
    return !hasErrors;
  }

  void _validateAntiCrawler() {
    if (captchaType == CaptchaType.imageCaptcha) {
      if (captchaImage.text.trim().isEmpty) {
        antiErrors.add('captchaImage');
      }
      if (captchaInput.text.trim().isEmpty) {
        antiErrors.add('captchaInput');
      }
      if (captchaButton.text.trim().isEmpty) {
        antiErrors.add('captchaButton');
      }
    } else if (captchaButton.text.trim().isEmpty) {
      antiErrors.add('captchaButton');
    }
  }

  void _validateApiSearch() {
    _requireApi(searchRequest.url, 'searchUrl');
    _requireApi(apiListPath, 'searchListPath');
    _requireApi(apiNamePath, 'searchNamePath');
    _requireApi(apiSourcePath, 'searchSourcePath');
    _validateJsonField(searchRequest.headers, 'searchHeaders');
    _validateJsonField(searchRequest.query, 'searchQuery');
    _validateJsonField(searchRequest.body, 'searchBody');
  }

  void _validateApiChapter() {
    _requireApi(chapterRequest.url, 'chapterUrl');
    if (chapterFormat == ApiChapterFormat.delimited) {
      _requireApi(apiRoadNamesPath, 'roadNamesPath');
      _requireApi(apiRoadEpisodesPath, 'roadEpisodesPath');
      _requireApi(apiRoadSeparator, 'roadSeparator');
      _requireApi(apiEpisodeSeparator, 'episodeSeparator');
      _requireApi(apiFieldSeparator, 'fieldSeparator');
    } else {
      _requireApi(apiEpisodesPath, 'episodesPath');
      if (episodePageEnabled) {
        _requireApi(episodePageUrl, 'episodePageUrl');
      } else {
        _requireApi(apiEpisodeUrlPath, 'episodeUrlPath');
      }
    }
    _validateJsonField(chapterRequest.headers, 'chapterHeaders');
    _validateJsonField(chapterRequest.query, 'chapterQuery');
    _validateJsonField(chapterRequest.body, 'chapterBody');
    _validateJsonField(apiVariables, 'chapterVariables');
    if (episodePageEnabled) {
      _validateJsonField(episodePageQuery, 'episodePageQuery');
    }
  }

  void _requireXPath(List<int> indexes) {
    for (final index in indexes) {
      if (xpathControllers[index].text.trim().isEmpty) {
        xpathErrors.add(index);
      }
    }
  }

  void _requireApi(TextEditingController controller, String key) {
    if (controller.text.trim().isEmpty) {
      apiErrors.add(key);
    }
  }

  void _validateJsonField(TextEditingController controller, String key) {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    try {
      jsonDecode(text);
    } catch (_) {
      apiErrors.add('${PluginFormController.jsonErrorPrefix}$key');
    }
  }
}

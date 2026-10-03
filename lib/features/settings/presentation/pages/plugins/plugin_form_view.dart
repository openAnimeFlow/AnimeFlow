import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/crawler/item/anti_crawler_config.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:flutter/material.dart';

import 'plugin_form_controller.dart';
import 'plugin_form_fields.dart';

/// 规则编辑器的分区布局。
///
/// 只读取 [PluginFormController] 的状态，所有交互通过 controller 的方法回写，
/// 具体的输入组件由 [PluginFormFields] 提供。
class PluginFormView {
  const PluginFormView._();

  /// 组装完整表单。
  static List<Widget> sections(
    BuildContext context,
    PluginFormController form,
  ) {
    return [
      ...basicSection(context, form),
      ...searchSection(context, form),
      ...chapterSection(context, form),
      ...antiCrawlerSection(context, form),
    ];
  }

  static List<Widget> basicSection(
    BuildContext context,
    PluginFormController form,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      PluginFormFields.sectionTitle(context, l10n.sectionBasic),
      for (final index in PluginFormIndex.basic)
        PluginFormFields.xpathFieldTile(context, form, index),
    ];
  }

  static List<Widget> searchSection(
    BuildContext context,
    PluginFormController form,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      PluginFormFields.sectionTitle(context, l10n.sectionSearch),
      PluginFormFields.modeSelector(
        context,
        label: l10n.searchModeLabel,
        value: form.searchMode,
        onChanged: form.setSearchMode,
      ),
      if (form.searchMode == RuleMode.xpath)
        for (final index in PluginFormIndex.xpathSearch)
          PluginFormFields.xpathFieldTile(context, form, index)
      else ...[
        ..._apiRequestFields(
          context,
          form,
          form.searchRequest,
          isSearch: true,
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiListPath,
          label: l10n.apiListPath,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'searchListPath'),
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiNamePath,
          label: l10n.apiNamePath,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'searchNamePath'),
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiSourcePath,
          label: l10n.apiSourcePath,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'searchSourcePath'),
        ),
      ],
    ];
  }

  static List<Widget> chapterSection(
    BuildContext context,
    PluginFormController form,
  ) {
    final l10n = AppLocalizations.of(context);
    final modeSelector = PluginFormFields.modeSelector(
      context,
      label: l10n.chapterModeLabel,
      value: form.chapterMode,
      onChanged: form.setChapterMode,
    );
    if (form.chapterMode == RuleMode.xpath) {
      return [
        PluginFormFields.sectionTitle(context, l10n.sectionChapter),
        modeSelector,
        for (final index in PluginFormIndex.xpathChapter)
          PluginFormFields.xpathFieldTile(context, form, index),
      ];
    }

    final nested = form.chapterFormat == ApiChapterFormat.nested;
    return [
      PluginFormFields.sectionTitle(context, l10n.sectionChapter),
      modeSelector,
      ..._apiRequestFields(
        context,
        form,
        form.chapterRequest,
        isSearch: false,
      ),
      PluginFormFields.dropdownField<String>(
        context,
        label: l10n.chapterFormat,
        items: const [ApiChapterFormat.nested, ApiChapterFormat.delimited],
        selected: form.chapterFormat,
        labelOf: (value) => value == ApiChapterFormat.delimited
            ? l10n.chapterFormatDelimited
            : l10n.chapterFormatNested,
        onSelected: form.setChapterFormat,
      ),
      if (nested) ...[
        PluginFormFields.labeledField(
          context,
          controller: form.apiRoadsPath,
          label: l10n.apiRoadsPath,
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiRoadNamePath,
          label: l10n.apiRoadNamePath,
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiEpisodesPath,
          label: l10n.apiEpisodesPath,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'episodesPath'),
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiEpisodeNamePath,
          label: l10n.apiEpisodeNamePath,
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiEpisodeUrlPath,
          label: l10n.apiEpisodeUrlPath,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'episodeUrlPath'),
        ),
      ] else ...[
        PluginFormFields.labeledField(
          context,
          controller: form.apiRoadNamesPath,
          label: l10n.apiRoadNamesPath,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'roadNamesPath'),
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiRoadEpisodesPath,
          label: l10n.apiRoadEpisodesPath,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'roadEpisodesPath'),
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiRoadSeparator,
          label: l10n.apiRoadSeparator,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'roadSeparator'),
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiEpisodeSeparator,
          label: l10n.apiEpisodeSeparator,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'episodeSeparator'),
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.apiFieldSeparator,
          label: l10n.apiFieldSeparator,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'fieldSeparator'),
        ),
      ],
      PluginFormFields.labeledField(
        context,
        controller: form.apiVariables,
        label: l10n.apiVariables,
        maxLines: 3,
        errorText:
            PluginFormFields.apiErrorText(context, form, 'chapterVariables'),
      ),
      SwitchListTile(
        title: Text(l10n.apiEpisodePage),
        value: form.episodePageEnabled,
        onChanged: form.setEpisodePageEnabled,
      ),
      if (form.episodePageEnabled) ...[
        PluginFormFields.labeledField(
          context,
          controller: form.episodePageUrl,
          label: l10n.apiEpisodePageUrl,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'episodePageUrl'),
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.episodePageQuery,
          label: l10n.apiEpisodePageQuery,
          maxLines: 3,
          errorText:
              PluginFormFields.apiErrorText(context, form, 'episodePageQuery'),
        ),
      ],
    ];
  }

  static List<Widget> _apiRequestFields(
    BuildContext context,
    PluginFormController form,
    ApiRequestControllers target, {
    required bool isSearch,
  }) {
    final l10n = AppLocalizations.of(context);
    final prefix = isSearch ? 'search' : 'chapter';

    return [
      PluginFormFields.dropdownField<String>(
        context,
        label: l10n.requestMethod,
        items: const ['GET', 'POST'],
        selected: target.method,
        labelOf: (value) => value,
        onSelected: (value) => form.setRequestMethod(target, value),
      ),
      PluginFormFields.labeledField(
        context,
        controller: target.url,
        label: l10n.requestUrl,
        errorText: PluginFormFields.apiErrorText(context, form, '${prefix}Url'),
      ),
      PluginFormFields.labeledField(
        context,
        controller: target.headers,
        label: l10n.requestHeaders,
        maxLines: 3,
        errorText:
            PluginFormFields.apiErrorText(context, form, '${prefix}Headers'),
      ),
      PluginFormFields.labeledField(
        context,
        controller: target.query,
        label: l10n.requestQuery,
        maxLines: 3,
        errorText:
            PluginFormFields.apiErrorText(context, form, '${prefix}Query'),
      ),
      PluginFormFields.dropdownField<String>(
        context,
        label: l10n.requestBodyType,
        items: const [ApiBodyType.none, ApiBodyType.json, ApiBodyType.form],
        selected: target.bodyType,
        labelOf: (value) => switch (value) {
          ApiBodyType.json => l10n.bodyTypeJson,
          ApiBodyType.form => l10n.bodyTypeForm,
          _ => l10n.bodyTypeNone,
        },
        onSelected: (value) => form.setRequestBodyType(target, value),
      ),
      if (target.bodyType != ApiBodyType.none)
        PluginFormFields.labeledField(
          context,
          controller: target.body,
          label: l10n.requestBody,
          maxLines: 4,
          errorText:
              PluginFormFields.apiErrorText(context, form, '${prefix}Body'),
        ),
    ];
  }

  static List<Widget> antiCrawlerSection(
    BuildContext context,
    PluginFormController form,
  ) {
    final l10n = AppLocalizations.of(context);
    final showImageCaptchaFields =
        form.antiEnabled && form.captchaType == CaptchaType.imageCaptcha;

    return [
      PluginFormFields.sectionTitle(context, l10n.antiCrawlerOptional),
      SwitchListTile(
        title: Text(l10n.enableWebViewCaptcha),
        subtitle: Text(l10n.webViewCaptchaSubtitle),
        value: form.antiEnabled,
        onChanged: form.setAntiEnabled,
      ),
      if (form.antiEnabled) ...[
        PluginFormFields.dropdownField<int>(
          context,
          label: l10n.captchaType,
          items: const [CaptchaType.imageCaptcha, CaptchaType.autoClickButton],
          selected: form.captchaType,
          labelOf: (value) => value == CaptchaType.autoClickButton
              ? l10n.autoClickCaptcha
              : l10n.imageCaptchaManual,
          onSelected: form.setCaptchaType,
        ),
        PluginFormFields.dropdownField<int>(
          context,
          label: l10n.captchaDetectType,
          items: const [
            CaptchaDetectType.xpath,
            CaptchaDetectType.text,
            CaptchaDetectType.regex,
          ],
          selected: form.captchaDetectType,
          labelOf: (value) => switch (value) {
            CaptchaDetectType.text => l10n.captchaDetectText,
            CaptchaDetectType.regex => l10n.captchaDetectRegex,
            _ => 'XPath',
          },
          onSelected: form.setCaptchaDetectType,
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.captchaDetectValue,
          label: l10n.captchaDetectValue,
        ),
        PluginFormFields.labeledField(
          context,
          controller: form.captchaPageUrl,
          label: l10n.captchaPageUrl,
          hint: l10n.searchLinkHint('{keyword}'),
        ),
        if (showImageCaptchaFields) ...[
          PluginFormFields.labeledField(
            context,
            controller: form.captchaImage,
            label: l10n.captchaImageXPath,
            hint: l10n.captchaImageXPathHint,
            errorText:
                PluginFormFields.antiErrorText(context, form, 'captchaImage'),
          ),
          PluginFormFields.labeledField(
            context,
            controller: form.captchaInput,
            label: l10n.captchaInputXPath,
            hint: l10n.captchaInputXPathHint,
            errorText:
                PluginFormFields.antiErrorText(context, form, 'captchaInput'),
          ),
        ],
        PluginFormFields.labeledField(
          context,
          controller: form.captchaButton,
          label: form.captchaType == CaptchaType.imageCaptcha
              ? l10n.submitCaptchaXPath
              : l10n.verifyButtonXPath,
          hint: form.captchaType == CaptchaType.imageCaptcha
              ? l10n.submitCaptchaHint
              : l10n.autoClickCaptchaHint,
          errorText:
              PluginFormFields.antiErrorText(context, form, 'captchaButton'),
        ),
      ],
    ];
  }
}

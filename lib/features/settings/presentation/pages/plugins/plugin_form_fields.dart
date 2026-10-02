import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:flutter/material.dart';

import 'plugin_form_controller.dart';

/// 字段的标题与说明。
class _FieldMeta {
  const _FieldMeta({required this.title, required this.message});

  final String title;
  final String message;
}

/// 规则编辑器的通用输入组件。
///
/// 只关心「怎么画一个带标签/提示/错误态的输入项」，
/// 具体有哪些字段、何时显示由 `PluginFormView` 决定。
class PluginFormFields {
  const PluginFormFields._();

  static Widget sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  static Widget modeSelector(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: RuleMode.xpath,
                label: Text('XPath'),
              ),
              ButtonSegment<String>(value: RuleMode.api, label: Text('API')),
            ],
            selected: <String>{value},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ],
      ),
    );
  }

  static Widget labeledField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    String? hint,
    String? errorText,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              errorText: errorText,
              errorBorder: errorText == null ? null : _errorBorder(context),
              focusedErrorBorder:
                  errorText == null ? null : _errorBorder(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (hint != null) _hintText(context, hint),
        ],
      ),
    );
  }

  static Widget dropdownField<T>(
    BuildContext context, {
    required String label,
    required List<T> items,
    required T selected,
    required String Function(T value) labelOf,
    required ValueChanged<T> onSelected,
    String? errorText,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          errorBorder: errorText == null ? null : _errorBorder(context),
          focusedErrorBorder: errorText == null ? null : _errorBorder(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: DropDownMenu<T>(
          items: items,
          selectedItem: selected,
          buttonBuilder: (context, item) => Row(
            children: [
              Text(item == null ? '' : labelOf(item)),
              const Spacer(),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
          itemBuilder: (context, item, isSelected) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(labelOf(item)),
              if (isSelected) ...[
                const SizedBox(width: 12),
                const Icon(Icons.check, size: 18),
              ],
            ],
          ),
          onSelected: onSelected,
        ),
      ),
    );
  }

  /// 既有 XPath 字段：标题与说明来自本地化文案，错误态来自表单校验。
  static Widget xpathFieldTile(
    BuildContext context,
    PluginFormController form,
    int index,
  ) {
    final l10n = AppLocalizations.of(context);
    final meta = _metaFor(index, l10n);
    return labeledField(
      context,
      controller: form.xpathControllers[index],
      label: meta.title,
      hint: meta.message,
      errorText: form.xpathErrors.contains(index) ? l10n.fieldRequired : null,
    );
  }

  /// API 字段的错误文案：区分「必填」与「JSON 格式错误」。
  static String? apiErrorText(
    BuildContext context,
    PluginFormController form,
    String key,
  ) {
    final l10n = AppLocalizations.of(context);
    if (form.apiErrors.contains(key)) return l10n.fieldRequired;
    if (form.apiErrors
        .contains('${PluginFormController.jsonErrorPrefix}$key')) {
      return l10n.invalidJsonFormat;
    }
    return null;
  }

  /// 反爬字段的错误文案。
  static String? antiErrorText(
    BuildContext context,
    PluginFormController form,
    String key,
  ) {
    if (!form.antiErrors.contains(key)) return null;
    return AppLocalizations.of(context).fieldRequired;
  }

  static OutlineInputBorder _errorBorder(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.error,
        width: 2,
      ),
    );
  }

  static Widget _hintText(BuildContext context, String message) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static _FieldMeta _metaFor(int index, AppLocalizations l10n) {
    return switch (index) {
      PluginFormIndex.version => _FieldMeta(
          title: l10n.versionNumber,
          message: l10n.versionExample,
        ),
      PluginFormIndex.name => _FieldMeta(
          title: l10n.sourceName,
          message: l10n.sourceNameHint,
        ),
      PluginFormIndex.icon => _FieldMeta(
          title: l10n.iconLink,
          message: l10n.iconLink,
        ),
      PluginFormIndex.baseUrl => _FieldMeta(
          title: l10n.websiteLink,
          message: l10n.websiteLinkHint,
        ),
      PluginFormIndex.searchUrl => _FieldMeta(
          title: l10n.searchLink,
          message: l10n.searchLinkHint('{keyword}'),
        ),
      PluginFormIndex.searchList => _FieldMeta(
          title: l10n.searchContentList,
          message: l10n.searchContentList,
        ),
      PluginFormIndex.searchName => _FieldMeta(
          title: l10n.searchListName,
          message: l10n.searchListName,
        ),
      PluginFormIndex.searchLink => _FieldMeta(
          title: l10n.searchListLink,
          message: l10n.searchListLink,
        ),
      PluginFormIndex.lineNames => _FieldMeta(
          title: l10n.lineName,
          message: l10n.lineName,
        ),
      PluginFormIndex.lineList => _FieldMeta(
          title: l10n.episodeList,
          message: l10n.episodeList,
        ),
      PluginFormIndex.episode => _FieldMeta(
          title: l10n.episode,
          message: l10n.episodeHint,
        ),
      _ => const _FieldMeta(title: '', message: ''),
    };
  }
}

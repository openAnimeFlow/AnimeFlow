import 'dart:convert';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/crawler/api_crawler.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_api_level.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/features/settings/presentation/pages/plugins/plugin_form_controller.dart';
import 'package:anime_flow/features/settings/presentation/pages/plugins/plugin_form_validation.dart';
import 'package:anime_flow/features/settings/presentation/pages/plugins/plugin_form_view.dart';
import 'package:anime_flow/features/source/application/providers/source_repository_provider.dart';
import 'package:anime_flow/features/source/data/repositories/source_repository.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 新增 / 编辑数据源规则的页面。
///
/// 表单状态与校验在 [PluginFormController]，字段渲染在 [PluginFormView]，
/// 本文件只负责页面生命周期、保存与导入。
class AddPluginsPage extends ConsumerStatefulWidget {
  final String? editPluginKey;

  const AddPluginsPage({super.key, this.editPluginKey});

  @override
  ConsumerState<AddPluginsPage> createState() => _AddPluginsPageState();
}

class _AddPluginsPageState extends ConsumerState<AddPluginsPage> {
  final PluginFormController _form = PluginFormController();

  SourceRepository get sourceRepository => ref.read(sourceRepositoryProvider);

  /// 编辑模式下用于替换旧规则的原名。
  String? _originalKey;

  /// 编辑已有规则时保留其声明的 api 级别，避免保存时被悄悄降级。
  String? _originalApi;

  @override
  void initState() {
    super.initState();
    _form.onChanged = () {
      if (mounted) setState(() {});
    };

    _originalKey = widget.editPluginKey;
    if (_originalKey != null) {
      _loadEditSource();
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _loadEditSource() async {
    final editConfig = await sourceRepository.getSource(_originalKey!);
    if (editConfig == null || !mounted) return;
    setState(() {
      _originalApi = editConfig.api;
      _form.loadFrom(editConfig);
    });
  }

  Future<bool> _saveConfig() async {
    if (!_form.validate()) {
      setState(() {});
      return false;
    }

    try {
      // API 模式规则至少声明到 API 级别，且不降级导入时已有的更高声明。
      final api = RuleApiLevel.declarationFor(
        usesApiSearch: _form.searchMode == RuleMode.api,
        usesApiChapter: _form.chapterMode == RuleMode.api,
        declared: _originalApi,
      );
      final item = _form.build(api: api);

      // 保存前用与运行期一致的校验，避免存进无法执行的规则。
      // 只校验当前启用的模式，未激活的一侧允许保持半成品配置。
      if (_form.searchMode == RuleMode.api) {
        ApiCrawler.validateSearchConfig(item.searchApiConfig);
      }
      if (_form.chapterMode == RuleMode.api) {
        ApiCrawler.validateChapterConfig(item.chapterApiConfig);
      }

      await sourceRepository.saveSource(item, originalName: _originalKey);
      return true;
    } catch (e, stackTrace) {
      // 保存失败同样进错误日志：规则问题不该只在页面上闪一下。
      LiggLogger().e(
        'AddPlugins: 保存规则失败',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        NotificationToast.show(
          l10n.dataSaveFailed(e.toString()),
          title: l10n.saveFailed,
        );
      }
      return false;
    }
  }

  Future<void> _pastePluginConfig() async {
    final l10n = AppLocalizations.of(context);
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final content = clipboardData?.text ?? '';

      if (!mounted) return;
      final controller = TextEditingController(text: content);
      final editedContent = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.pastePlugin),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360, maxWidth: 450),
            child: TextField(
              controller: controller,
              minLines: 8,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(l10n.importPlugin),
            ),
          ],
        ),
      );
      controller.dispose();
      if (editedContent == null || !mounted) return;
      if (editedContent.trim().isEmpty) {
        throw const FormatException('剪切板中没有插件配置');
      }

      final decoded = jsonDecode(editedContent);
      if (decoded is! Map) {
        throw const FormatException('插件配置格式无效');
      }
      final config = CrawlConfigItem.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (config.name.trim().isEmpty) {
        throw const FormatException('插件名称不能为空');
      }
      if (!config.isRuleCompatible) {
        throw FormatException(
          RuleApiLevel.describe(config.api, ruleName: config.name),
        );
      }

      setState(() {
        _originalApi = config.api;
        _form.loadFrom(config);
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      LiggLogger().e(
        'AddPlugins: 导入规则失败',
        error: error,
        stackTrace: stackTrace,
      );
      NotificationToast.show(
        l10n.pluginImportFailed(error.toString()),
        title: l10n.pastePlugin,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_originalKey != null ? l10n.editSource : l10n.addSource),
        actions: [
          IconButton(
            tooltip: l10n.pastePlugin,
            onPressed: _pastePluginConfig,
            icon: const Icon(Icons.content_paste),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_source_save',
        onPressed: () async {
          final saved = await _saveConfig();
          if (saved && context.mounted) {
            context.pop();
          }
        },
        child: const Icon(Icons.save_rounded),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: PluginFormView.sections(context, _form),
          ),
        ),
      ),
    );
  }
}

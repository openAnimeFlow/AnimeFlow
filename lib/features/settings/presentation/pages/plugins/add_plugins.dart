import 'dart:convert';

import 'package:anime_flow/core/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/itme/anti_crawler_config.dart';
import 'package:anime_flow/features/source/data/repositories/source_repository.dart';
import 'package:anime_flow/features/source/application/providers/source_repository_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class AddPluginsPage extends ConsumerStatefulWidget {
  final String? editPluginKey;

  const AddPluginsPage({super.key, this.editPluginKey});

  @override
  ConsumerState<AddPluginsPage> createState() => _AddPluginsPageState();
}

class _AddPluginsPageState extends ConsumerState<AddPluginsPage> {
  static const _fieldCount = 11;

  List<_Field> _localizedTextFields(AppLocalizations l10n) => [
        _Field(
            title: l10n.versionNumber,
            message: l10n.versionExample,
            isRequired: true),
        _Field(
            title: l10n.sourceName,
            message: l10n.sourceNameHint,
            isRequired: true),
        _Field(title: l10n.iconLink, message: l10n.iconLink, isRequired: true),
        _Field(
            title: l10n.websiteLink,
            message: l10n.websiteLinkHint,
            isRequired: true),
        _Field(
            title: l10n.searchLink,
            message: l10n.searchLinkHint('{keyword}'),
            isRequired: true),
        _Field(
            title: l10n.searchContentList,
            message: l10n.searchContentList,
            isRequired: true),
        _Field(
            title: l10n.searchListName,
            message: l10n.searchListName,
            isRequired: true),
        _Field(
            title: l10n.searchListLink,
            message: l10n.searchListLink,
            isRequired: true),
        _Field(title: l10n.lineName, message: l10n.lineName, isRequired: true),
        _Field(
            title: l10n.episodeList,
            message: l10n.episodeList,
            isRequired: true),
        _Field(
            title: l10n.episode, message: l10n.episodeHint, isRequired: true),
      ];

  late final List<TextEditingController> _controllers;
  final Set<int> _errorFields = {};
  final Set<String> _antiFieldErrors = {};
  SourceRepository get sourceRepository => ref.read(sourceRepositoryProvider);
  String? _originalKey; // 保存原始key值，用于编辑模式下删除旧数据

  late final TextEditingController _captchaImageController;
  late final TextEditingController _captchaInputController;
  late final TextEditingController _captchaButtonController;
  bool _antiEnabled = false;
  int _captchaType = CaptchaType.imageCaptcha;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _fieldCount,
      (_) => TextEditingController(),
    );
    _captchaImageController = TextEditingController();
    _captchaInputController = TextEditingController();
    _captchaButtonController = TextEditingController();

    _originalKey = widget.editPluginKey;

    // 如果有key，从持久化存储中查询数据并填充表单
    if (_originalKey != null) {
      _loadEditSource();
    }
  }

  Future<void> _loadEditSource() async {
    final editConfig = await sourceRepository.getSource(_originalKey!);
    if (editConfig != null && mounted) {
      final anti = editConfig.antiCrawlerConfig;
      setState(() {
        _antiEnabled = anti.enabled;
        _captchaType = anti.captchaType;
        _captchaImageController.text = anti.captchaImage;
        _captchaInputController.text = anti.captchaInput;
        _captchaButtonController.text = anti.captchaButton;
        _controllers[0].text = editConfig.version;
        _controllers[1].text = editConfig.name;
        _controllers[2].text = editConfig.iconUrl;
        _controllers[3].text = editConfig.baseUrl;
        _controllers[4].text = editConfig.searchUrl;
        _controllers[5].text = editConfig.searchList;
        _controllers[6].text = editConfig.searchName;
        _controllers[7].text = editConfig.searchLink;
        _controllers[8].text = editConfig.lineNames;
        _controllers[9].text = editConfig.lineList;
        _controllers[10].text = editConfig.episode;
      });
    }

    // 监听输入变化，清除错误状态
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        if (_errorFields.contains(i) &&
            _controllers[i].text.trim().isNotEmpty) {
          setState(() {
            _errorFields.remove(i);
          });
        }
      });
    }
    void clearAntiError(String key) {
      if (_antiFieldErrors.contains(key)) {
        setState(() {
          _antiFieldErrors.remove(key);
        });
      }
    }

    _captchaImageController.addListener(() {
      if (_captchaImageController.text.trim().isNotEmpty) {
        clearAntiError('captchaImage');
      }
    });
    _captchaInputController.addListener(() {
      if (_captchaInputController.text.trim().isNotEmpty) {
        clearAntiError('captchaInput');
      }
    });
    _captchaButtonController.addListener(() {
      if (_captchaButtonController.text.trim().isNotEmpty) {
        clearAntiError('captchaButton');
      }
    });
  }

  Future<bool> _saveConfig() async {
    // 空值校验
    _errorFields.clear();
    for (int i = 0; i < _controllers.length; i++) {
      final controller = _controllers[i];
      final value = controller.text.trim();

      if (value.isEmpty) {
        _errorFields.add(i);
      }
    }

    _antiFieldErrors.clear();
    if (_antiEnabled) {
      if (_captchaType == CaptchaType.imageCaptcha) {
        if (_captchaImageController.text.trim().isEmpty) {
          _antiFieldErrors.add('captchaImage');
        }
        if (_captchaInputController.text.trim().isEmpty) {
          _antiFieldErrors.add('captchaInput');
        }
        if (_captchaButtonController.text.trim().isEmpty) {
          _antiFieldErrors.add('captchaButton');
        }
      } else {
        if (_captchaButtonController.text.trim().isEmpty) {
          _antiFieldErrors.add('captchaButton');
        }
      }
    }

    if (_errorFields.isNotEmpty || _antiFieldErrors.isNotEmpty) {
      setState(() {});
      return false;
    }

    try {
      final newName = _controllers[1].text.trim();
      final antiCrawlerConfig = AntiCrawlerConfig(
        enabled: _antiEnabled,
        captchaType: _captchaType,
        captchaImage: _captchaImageController.text.trim(),
        captchaInput: _captchaInputController.text.trim(),
        captchaButton: _captchaButtonController.text.trim(),
      );
      final item = CrawlConfigItem(
        version: _controllers[0].text.trim(),
        name: newName,
        iconUrl: _controllers[2].text.trim(),
        baseUrl: _controllers[3].text.trim(),
        searchUrl: _controllers[4].text.trim(),
        searchList: _controllers[5].text.trim(),
        searchName: _controllers[6].text.trim(),
        searchLink: _controllers[7].text.trim(),
        lineNames: _controllers[8].text.trim(),
        lineList: _controllers[9].text.trim(),
        episode: _controllers[10].text.trim(),
        antiCrawlerConfig: antiCrawlerConfig,
      );

      await sourceRepository.saveSource(item, originalName: _originalKey);
      return true;
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        NotificationToast.show(l10n.dataSaveFailed(e.toString()),
            title: l10n.saveFailed);
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

      setState(() {
        _antiEnabled = config.antiCrawlerConfig.enabled;
        _captchaType = config.antiCrawlerConfig.captchaType;
        _captchaImageController.text = config.antiCrawlerConfig.captchaImage;
        _captchaInputController.text = config.antiCrawlerConfig.captchaInput;
        _captchaButtonController.text = config.antiCrawlerConfig.captchaButton;
        _controllers[0].text = config.version;
        _controllers[1].text = config.name;
        _controllers[2].text = config.iconUrl;
        _controllers[3].text = config.baseUrl;
        _controllers[4].text = config.searchUrl;
        _controllers[5].text = config.searchList;
        _controllers[6].text = config.searchName;
        _controllers[7].text = config.searchLink;
        _controllers[8].text = config.lineNames;
        _controllers[9].text = config.lineList;
        _controllers[10].text = config.episode;
        _errorFields.clear();
        _antiFieldErrors.clear();
      });
    } catch (error) {
      if (!mounted) return;
      NotificationToast.show(
        l10n.pluginImportFailed(error.toString()),
        title: l10n.pastePlugin,
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _captchaImageController.dispose();
    _captchaInputController.dispose();
    _captchaButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localizedTextFields = _localizedTextFields(l10n);
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
            children: [
              ...List.generate(localizedTextFields.length, (index) {
                final textField = localizedTextFields[index];
                final controller = _controllers[index];
                final hasError = _errorFields.contains(index);
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: textField.title,
                          errorText: hasError ? l10n.fieldRequired : null,
                          errorBorder: hasError
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.error,
                                    width: 2,
                                  ),
                                )
                              : null,
                          focusedErrorBorder: hasError
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.error,
                                    width: 2,
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: Text(
                          textField.message,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }),
              ..._buildAntiCrawlerSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _antiTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool hasError,
  }) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        errorText: hasError ? l10n.fieldRequired : null,
        errorBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 2,
                ),
              )
            : null,
        focusedErrorBorder: hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 2,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  List<Widget> _buildAntiCrawlerSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showImageCaptchaFields =
        _antiEnabled && _captchaType == CaptchaType.imageCaptcha;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          l10n.antiCrawlerOptional,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SwitchListTile(
          title: Text(l10n.enableWebViewCaptcha),
          subtitle: Text(l10n.webViewCaptchaSubtitle),
          value: _antiEnabled,
          onChanged: (v) {
            setState(() {
              _antiEnabled = v;
            });
          },
        ),
      ),
      if (_antiEnabled) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.captchaType,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: DropDownMenu<int>(
              items: const [
                CaptchaType.imageCaptcha,
                CaptchaType.autoClickButton,
              ],
              selectedItem: _captchaType,
              buttonBuilder: (context, selectedType) {
                return Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedType == CaptchaType.autoClickButton
                            ? l10n.autoClickCaptcha
                            : l10n.imageCaptchaManual,
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                );
              },
              itemBuilder: (context, type, isSelected) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type == CaptchaType.autoClickButton
                          ? l10n.autoClickCaptcha
                          : l10n.imageCaptchaManual,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.check, size: 18),
                    ],
                  ],
                );
              },
              onSelected: (type) {
                setState(() {
                  _captchaType = type;
                });
              },
            ),
          ),
        ),
        if (showImageCaptchaFields) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _antiTextField(
                  context: context,
                  controller: _captchaImageController,
                  label: l10n.captchaImageXPath,
                  hasError: _antiFieldErrors.contains('captchaImage'),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    l10n.captchaImageXPathHint,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _antiTextField(
                  context: context,
                  controller: _captchaInputController,
                  label: l10n.captchaInputXPath,
                  hasError: _antiFieldErrors.contains('captchaInput'),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    l10n.captchaInputXPathHint,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _antiTextField(
                context: context,
                controller: _captchaButtonController,
                label: _captchaType == CaptchaType.imageCaptcha
                    ? l10n.submitCaptchaXPath
                    : l10n.verifyButtonXPath,
                hasError: _antiFieldErrors.contains('captchaButton'),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  _captchaType == CaptchaType.imageCaptcha
                      ? l10n.submitCaptchaHint
                      : l10n.autoClickCaptchaHint,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }
}

class _Field {
  final String title;
  final String message;
  final bool isRequired;

  _Field({
    required this.title,
    required this.message,
    this.isRequired = false,
  });
}

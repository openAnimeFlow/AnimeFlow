import 'package:anime_flow/crawler/itme/crawler_config_item.dart';
import 'package:anime_flow/crawler/itme/anti_crawler_config.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddPluginsPage extends StatefulWidget {
  final String? editPluginKey;

  const AddPluginsPage({super.key, this.editPluginKey});

  @override
  State<AddPluginsPage> createState() => _AddPluginsPageState();
}

class _AddPluginsPageState extends State<AddPluginsPage> {
  final List<_Field> _textFields = [
    _Field(
      title: '版本号',
      message: '如（1.0.0）',
      isRequired: true,
    ),
    _Field(
      title: '名称',
      message: '网站名称,唯一值避免与其他配置名称重复,否则将被覆盖',
      isRequired: true,
    ),
    _Field(
      title: '图标链接',
      message: '网站图标链接',
      isRequired: true,
    ),
    _Field(
      title: '网站链接',
      message: '网站主链接,避免以 / 结尾',
      isRequired: true,
    ),
    _Field(
      title: '搜索链接',
      message:
      '用{keyword}搜索关键字,示例:https://dm.xifanacg.com/search.html?wd={keyword}',
      isRequired: true,
    ),
    _Field(
      title: '搜索内容列表',
      message: '搜索内容列表',
      isRequired: true,
    ),
    _Field(
      title: '搜索列表名称',
      message: '搜索列表名称',
      isRequired: true,
    ),
    _Field(
      title: '搜索列表链接',
      message: '搜索列表链接',
      isRequired: true,
    ),
    _Field(
      title: '线路名称',
      message: '线路名称',
      isRequired: true,
    ),
    _Field(
      title: '剧集列表',
      message: '剧集列表',
      isRequired: true,
    ),
    _Field(
      title: '剧集',
      message: '剧集链接,从剧集列表中获取的数据的xpath',
      isRequired: true,
    )
  ];

  late final List<TextEditingController> _controllers;
  final Set<int> _errorFields = {};
  final Set<String> _antiFieldErrors = {};
  final crawlConfigs = Storage.crawlConfigs;
  String? _originalKey; // 保存原始key值，用于编辑模式下删除旧数据

  late final TextEditingController _captchaImageController;
  late final TextEditingController _captchaInputController;
  late final TextEditingController _captchaButtonController;
  bool _antiEnabled = false;
  int _captchaType = CaptchaType.imageCaptcha;

  @override
  void initState() {
    super.initState();
    _controllers = _textFields.map((field) => TextEditingController()).toList();
    _captchaImageController = TextEditingController();
    _captchaInputController = TextEditingController();
    _captchaButtonController = TextEditingController();

    _originalKey = widget.editPluginKey;

    // 如果有key，从持久化存储中查询数据并填充表单
    if (_originalKey != null) {
      final configData = crawlConfigs.get(_originalKey!);
      if (configData != null) {
        final editConfig = CrawlConfigItem.fromJson(
          Map<String, dynamic>.from(configData),
        );
        final anti = editConfig.antiCrawlerConfig;
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
      }
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
    for (int i = 0; i < _textFields.length; i++) {
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

      // 如果是编辑模式且名称（key）改变了，先删除旧的key
      if (_originalKey != null && _originalKey != newName) {
        await crawlConfigs.delete(_originalKey);
      }

      crawlConfigs.put(item.name, item.toJson());
      return true;
    } catch (e) {
      if (mounted) {
        NotificationToast.show('保存失败', '数据保存失败:$e');
      }
      return false;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_originalKey != null ? '编辑数据源' : '添加数据源'),
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
              ...List.generate(_textFields.length, (index) {
                final textField = _textFields[index];
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
                          errorText: hasError ? '此字段不能为空' : null,
                          errorBorder: hasError
                              ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color:
                              Theme.of(context).colorScheme.error,
                              width: 2,
                            ),
                          )
                              : null,
                          focusedErrorBorder: hasError
                              ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color:
                              Theme.of(context).colorScheme.error,
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        errorText: hasError ? '此字段不能为空' : null,
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
    final showImageCaptchaFields =
        _antiEnabled && _captchaType == CaptchaType.imageCaptcha;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          '反爬 / 验证码（可选）',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SwitchListTile(
          title: const Text('启用 WebView 验证码处理'),
          subtitle: const Text('搜索触发验证码时，用 WebView 完成验证并保存 Cookie'),
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
              labelText: '验证类型',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _captchaType,
                items: const [
                  DropdownMenuItem(
                    value: CaptchaType.imageCaptcha,
                    child: Text('图片验证码（手动输入）'),
                  ),
                  DropdownMenuItem(
                    value: CaptchaType.autoClickButton,
                    child: Text('自动点击验证按钮'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _captchaType = v;
                  });
                },
              ),
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
                  label: '验证码图片 XPath',
                  hasError: _antiFieldErrors.contains('captchaImage'),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    'WebView 内定位验证码图片元素',
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
                  label: '验证码输入框 XPath',
                  hasError: _antiFieldErrors.contains('captchaInput'),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    '供用户输入验证码的 input 元素',
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
                    ? '提交验证码按钮 XPath'
                    : '验证按钮 XPath',
                hasError: _antiFieldErrors.contains('captchaButton'),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  _captchaType == CaptchaType.imageCaptcha
                      ? '点击后提交验证码的按钮'
                      : '检测到后自动点击的验证按钮（如「我不是机器人」）',
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

import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddSourcePage extends StatefulWidget {
  const AddSourcePage({super.key});

  @override
  State<AddSourcePage> createState() => _AddSourcePageState();
}

class _AddSourcePageState extends State<AddSourcePage> {
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
  final crawlConfigs = Storage.crawlConfigs;
  String? _originalKey; // 保存原始key值，用于编辑模式下删除旧数据

  @override
  void initState() {
    super.initState();
    _controllers = _textFields.map((field) => TextEditingController()).toList();

    // 获取传递的key值（可能是null，表示添加新数据源）
    final arguments = Get.arguments;
    final key = arguments is String ? arguments : null;
    _originalKey = key;

    // 如果有key，从持久化存储中查询数据并填充表单
    if (key != null) {
      final configData = crawlConfigs.get(key);
      if (configData != null) {
        final editConfig = CrawlConfigItem.fromJson(
          Map<String, dynamic>.from(configData),
        );
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
  }

  Future<void> _saveConfig() async {
    // 空值校验
    _errorFields.clear();
    for (int i = 0; i < _textFields.length; i++) {
      final controller = _controllers[i];
      final value = controller.text.trim();

      if (value.isEmpty) {
        _errorFields.add(i);
      }
    }

    if (_errorFields.isNotEmpty) {
      setState(() {});
      return;
    }

    try {
      final newName = _controllers[1].text.trim();
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
      );
      
      // 如果是编辑模式且名称（key）改变了，先删除旧的key
      if (_originalKey != null && _originalKey != newName) {
        await crawlConfigs.delete(_originalKey);
      }
      
      crawlConfigs.put(item.name, item.toJson());
      Get.back(result: true);
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          '保存失败',
          '数据保存失败:$e',
          maxWidth: 400,
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
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
        onPressed: _saveConfig,
        child: const Icon(Icons.save_rounded),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: List.generate(_textFields.length, (index) {
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
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

import 'package:anime_flow/models/item/crawler_config_item.dart';
import 'package:anime_flow/utils/crawl_config.dart';
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
      message: '用{keyword}搜索关键字,示例:https://dm.xifanacg.com/search.html?wd={keyword}',
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

  @override
  void initState() {
    super.initState();
    _controllers = _textFields.map((field) => TextEditingController()).toList();
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
      final item = CrawlConfigItem(
        version: _controllers[0].text.trim(),
        name: _controllers[1].text.trim(),
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

      await CrawlConfig.saveCrawl(item);

      if (mounted) {
        Get.snackbar(
          '保存成功',
          '数据源已保存',
          maxWidth: 400,
        );
        Navigator.of(context).pop(true); // 返回 true 表示保存成功
      }
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
        title: Text('数据源管理'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveConfig,
        child: const Icon(Icons.save_rounded),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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

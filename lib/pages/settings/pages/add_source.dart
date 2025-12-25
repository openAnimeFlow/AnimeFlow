import 'package:flutter/material.dart';

class AddSourcePage extends StatefulWidget {
  const AddSourcePage({super.key});

  @override
  State<AddSourcePage> createState() => _AddSourcePageState();
}

class _AddSourcePageState extends State<AddSourcePage> {
  final List<String> _textField = [
    '版本号',
    '名称',
    '图标链接',
    '网站链接',
    '搜索链接',
    '搜索内容列表',
    '搜索列表名称',
    '搜索列表链接',
    '线路名称',
    '剧集列表',
    '剧集'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('数据源管理'),
      ),
      //右下角按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.save_rounded),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              children: List.generate(_textField.length, (index) {
                final String text = _textField[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: text,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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

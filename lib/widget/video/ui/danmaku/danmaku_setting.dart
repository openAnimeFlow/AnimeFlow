import 'package:flutter/material.dart';

/// 弹幕设置弹窗
class DanmakuSetting extends StatefulWidget {
  const DanmakuSetting({super.key});

  @override
  State<DanmakuSetting> createState() => _DanmakuSettingState();
}

class _DanmakuSettingState extends State<DanmakuSetting> {
  // 弹幕设置状态
  bool _border = true;
  double _opacity = 1.0;
  double _fontSize = 20.0;
  bool _hideTop = false;
  bool _hideBottom = false;
  bool _hideScroll = false;
  bool _massiveMode = false;
  bool _danmakuColor = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部指示条
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '弹幕设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
          _buildSettingItem(
            title: '显示边框',
            value: _border,
            onChanged: (value) {
              setState(() {
                _border = value;
              });
            },
          ),
          _buildSettingItem(
            title: '显示颜色',
            value: _danmakuColor,
            onChanged: (value) {
              setState(() {
                _danmakuColor = value;
              });
            },
          ),
          _buildSettingItem(
            title: '隐藏顶部弹幕',
            value: _hideTop,
            onChanged: (value) {
              setState(() {
                _hideTop = value;
              });
            },
          ),
          _buildSettingItem(
            title: '隐藏底部弹幕',
            value: _hideBottom,
            onChanged: (value) {
              setState(() {
                _hideBottom = value;
              });
            },
          ),
          _buildSettingItem(
            title: '隐藏滚动弹幕',
            value: _hideScroll,
            onChanged: (value) {
              setState(() {
                _hideScroll = value;
              });
            },
          ),
          _buildSettingItem(
            title: '密集模式',
            value: _massiveMode,
            onChanged: (value) {
              setState(() {
                _massiveMode = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // 透明度滑块
          Text(
            '透明度: ${(_opacity * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Slider(
            value: _opacity,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              setState(() {
                _opacity = value;
              });
            },
          ),
          const SizedBox(height: 8),
          // 字体大小滑块
          Text(
            '字体大小: ${_fontSize.toInt()}px',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Slider(
            value: _fontSize,
            min: 12.0,
            max: 30.0,
            divisions: 18,
            onChanged: (value) {
              setState(() {
                _fontSize = value;
              });
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

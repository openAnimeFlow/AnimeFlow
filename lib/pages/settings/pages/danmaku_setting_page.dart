import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/pages/settings/setting_controller.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class DanmakuSettingPage extends StatefulWidget {
  const DanmakuSettingPage({super.key});

  @override
  State<DanmakuSettingPage> createState() => _DanmakuSettingPageState();
}

class _DanmakuSettingPageState extends State<DanmakuSettingPage> {
  late SettingController settingController;
  Box setting = Storage.setting;

  // 弹幕配置状态
  late double _opacity;
  late double _fontSize;
  late double _danmakuArea;
  late double _danmakuDuration;
  late bool _massiveMode;
  late bool _border;
  late bool _danmakuColor;
  late bool _hideTop;
  late bool _hideBottom;
  late bool _hideScroll;
  late bool _platformBilibili;
  late bool _platformGamer;
  late bool _platformDanDanPlay;

  @override
  void initState() {
    super.initState();
    settingController = Get.find<SettingController>();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _opacity = setting.get(DanmakuKey.danmakuOpacity, defaultValue: 1.0);
      _fontSize = setting.get(DanmakuKey.danmakuFontSize,
          defaultValue: Utils.isMobile ? 16.0 : 25.0);
      _danmakuArea = setting.get(DanmakuKey.danmakuArea, defaultValue: 1.0);
      _danmakuDuration =
          setting.get(DanmakuKey.danmakuDuration, defaultValue: 8.0);
      _massiveMode =
          setting.get(DanmakuKey.danmakuMassiveMode, defaultValue: false);
      _border = setting.get(DanmakuKey.danmakuBorder, defaultValue: true);
      _danmakuColor = setting.get(DanmakuKey.danmakuColor, defaultValue: true);
      _hideTop = setting.get(DanmakuKey.danmakuHideTop, defaultValue: false);
      _hideBottom =
          setting.get(DanmakuKey.danmakuHideBottom, defaultValue: false);
      _hideScroll =
          setting.get(DanmakuKey.danmakuHideScroll, defaultValue: false);
      _platformBilibili =
          setting.get(DanmakuKey.danmakuPlatformBilibili, defaultValue: true);
      _platformGamer =
          setting.get(DanmakuKey.danmakuPlatformGamer, defaultValue: true);
      _platformDanDanPlay = setting.get(
          DanmakuKey.danmakuPlatformDanDanPlay, defaultValue: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          appBar: AppBar(
            title: const Text('弹幕设置'),
            automaticallyImplyLeading: !settingController.isWideScreen.value,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 弹幕显示类型
              _buildSectionTitle('弹幕显示类型'),
              SwitchListTile(
                title: const Text('滚动弹幕'),
                value: !_hideScroll,
                onChanged: (value) {
                  setState(() {
                    _hideScroll = !value;
                    setting.put(DanmakuKey.danmakuHideScroll, _hideScroll);
                  });
                },
              ),
              SwitchListTile(
                title: const Text('顶部弹幕'),
                value: !_hideTop,
                onChanged: (value) {
                  setState(() {
                    _hideTop = !value;
                    setting.put(DanmakuKey.danmakuHideTop, _hideTop);
                  });
                },
              ),
              SwitchListTile(
                title: const Text('底部弹幕'),
                value: !_hideBottom,
                onChanged: (value) {
                  setState(() {
                    _hideBottom = !value;
                    setting.put(DanmakuKey.danmakuHideBottom, _hideBottom);
                  });
                },
              ),
              const SizedBox(height: 16),

              // 弹幕来源平台
              _buildSectionTitle('弹幕来源平台'),
              SwitchListTile(
                title: const Text('Bilibili'),
                value: _platformBilibili,
                onChanged: (value) {
                  setState(() {
                    _platformBilibili = value;
                    setting.put(DanmakuKey.danmakuPlatformBilibili, value);
                  });
                  // 同步更新 PlayController 的平台隐藏状态
                  try {
                    final playController = Get.find<PlayController>();
                    playController.syncPlatformVisibilityFromStorage();
                  } catch (_) {
                    // PlayController 可能未初始化，忽略错误
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Gamer'),
                value: _platformGamer,
                onChanged: (value) {
                  setState(() {
                    _platformGamer = value;
                    setting.put(DanmakuKey.danmakuPlatformGamer, value);
                  });
                  // 同步更新 PlayController 的平台隐藏状态
                  try {
                    final playController = Get.find<PlayController>();
                    playController.syncPlatformVisibilityFromStorage();
                  } catch (_) {
                    // PlayController 可能未初始化，忽略错误
                  }
                },
              ),
              SwitchListTile(
                title: const Text('弹弹Play'),
                value: _platformDanDanPlay,
                onChanged: (value) {
                  setState(() {
                    _platformDanDanPlay = value;
                    setting.put(DanmakuKey.danmakuPlatformDanDanPlay, value);
                  });
                  // 同步更新 PlayController 的平台隐藏状态
                  try {
                    final playController = Get.find<PlayController>();
                    playController.syncPlatformVisibilityFromStorage();
                  } catch (_) {
                    // PlayController 可能未初始化，忽略错误
                  }
                },
              ),
              const SizedBox(height: 16),

              // 弹幕样式
              _buildSectionTitle('弹幕样式'),
              SwitchListTile(
                title: const Text('显示边框'),
                value: _border,
                onChanged: (value) {
                  setState(() {
                    _border = value;
                    setting.put(DanmakuKey.danmakuBorder, _border);
                  });
                },
              ),
              SwitchListTile(
                title: const Text('显示颜色'),
                value: _danmakuColor,
                onChanged: (value) {
                  setState(() {
                    _danmakuColor = value;
                    setting.put(DanmakuKey.danmakuColor, _danmakuColor);
                  });
                },
              ),
              SwitchListTile(
                title: const Text('密集模式'),
                value: _massiveMode,
                onChanged: (value) {
                  setState(() {
                    _massiveMode = value;
                    setting.put(DanmakuKey.danmakuMassiveMode, _massiveMode);
                  });
                },
              ),
              const SizedBox(height: 16),

              // 弹幕速度
              _buildSectionTitle('弹幕速度'),
              Builder(
                builder: (context) {
                  // duration 范围：2.0 (最快) 到 16.0 (最慢)
                  // 速度百分比：0% (最慢) 到 100% (最快)
                  const minDuration = 2.0;
                  const maxDuration = 16.0;
                  final currentDuration =
                      _danmakuDuration.clamp(minDuration, maxDuration);
                  final speedPercent = ((maxDuration - currentDuration) /
                          (maxDuration - minDuration) *
                          100)
                      .round();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '速度: $speedPercent%',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 15,
                        ),
                        child: Slider(
                          value: speedPercent.toDouble(),
                          min: 0.0,
                          max: 100.0,
                          divisions: 20,
                          label: '$speedPercent%',
                          onChanged: (speedPercentValue) {
                            setState(() {
                              // 将速度百分比转换回 duration
                              final newDuration = maxDuration -
                                  (speedPercentValue / 100.0) *
                                      (maxDuration - minDuration);
                              _danmakuDuration = newDuration;
                              setting.put(DanmakuKey.danmakuDuration, newDuration);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // 透明度
              _buildSectionTitle('透明度'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${(_opacity * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 15,
                    ),
                    child: Slider(
                      value: _opacity,
                      min: 0.1,
                      max: 1.0,
                      label: '${(_opacity * 100).round()}%',
                      onChanged: (value) {
                        setState(() {
                          _opacity = value;
                          setting.put(DanmakuKey.danmakuOpacity, _opacity);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 字体大小
              _buildSectionTitle('字体大小'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${_fontSize.toInt()}px',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 15,
                    ),
                    child: Slider(
                      value: _fontSize,
                      min: 12.0,
                      max: 30.0,
                      divisions: 18,
                      label: '${_fontSize.toInt()}px',
                      onChanged: (value) {
                        setState(() {
                          _fontSize = value;
                          setting.put(DanmakuKey.danmakuFontSize, _fontSize);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 显示区域
              _buildSectionTitle('显示区域'),
              Builder(
                builder: (context) {
                  final fixedValues = [0.1, 0.25, 0.5, 0.75, 1.0];
                  int currentIndex = 0;
                  for (int i = 0; i < fixedValues.length; i++) {
                    if ((_danmakuArea - fixedValues[i]).abs() < 0.01) {
                      currentIndex = i;
                      break;
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${(_danmakuArea * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 15,
                        ),
                        child: Slider(
                          value: currentIndex.toDouble(),
                          min: 0.0,
                          max: 4.0,
                          divisions: 4,
                          label: '${(_danmakuArea * 100).toInt()}%',
                          onChanged: (value) {
                            final index = value.round().clamp(0, 4);
                            setState(() {
                              _danmakuArea = fixedValues[index];
                              setting.put(DanmakuKey.danmakuArea, _danmakuArea);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
    );
  }
}

import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_chinese_mode_provider.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class DanmakuSettingPage extends StatefulWidget {
  const DanmakuSettingPage({super.key});

  @override
  State<DanmakuSettingPage> createState() => _DanmakuSettingPageState();
}

class _DanmakuSettingPageState extends State<DanmakuSettingPage> {
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
  bool _isChineseModeMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _opacity = AppSettings.danmakuOpacity;
      _fontSize = AppSettings.danmakuFontSize;
      _danmakuArea = AppSettings.danmakuArea;
      _danmakuDuration = AppSettings.danmakuDuration;
      _massiveMode = AppSettings.danmakuMassiveMode;
      _border = AppSettings.danmakuBorder;
      _danmakuColor = AppSettings.danmakuColor;
      _hideTop = AppSettings.danmakuHideTop;
      _hideBottom = AppSettings.danmakuHideBottom;
      _hideScroll = AppSettings.danmakuHideScroll;
      _platformBilibili = AppSettings.danmakuPlatformBilibili;
      _platformGamer = AppSettings.danmakuPlatformGamer;
      _platformDanDanPlay = AppSettings.danmakuPlatformDanDanPlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: Text(l10n.danmakuSettings),
              automaticallyImplyLeading: !isWideScreen,
            );
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            // 隐藏滚动条
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 弹幕显示类型
                  _buildSectionTitle(l10n.danmakuDisplayType),
                  SwitchListTile(
                    title: Text(l10n.scrollingDanmaku),
                    value: !_hideScroll,
                    onChanged: (value) {
                      setState(() {
                        _hideScroll = !value;
                        AppSettings.setDanmakuValue(
                            DanmakuKey.danmakuHideScroll, _hideScroll);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(l10n.topDanmaku),
                    value: !_hideTop,
                    onChanged: (value) {
                      setState(() {
                        _hideTop = !value;
                        AppSettings.setDanmakuValue(
                            DanmakuKey.danmakuHideTop, _hideTop);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(l10n.bottomDanmaku),
                    value: !_hideBottom,
                    onChanged: (value) {
                      setState(() {
                        _hideBottom = !value;
                        AppSettings.setDanmakuValue(
                            DanmakuKey.danmakuHideBottom, _hideBottom);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 弹幕来源平台
                  _buildSectionTitle(l10n.danmakuSourcePlatform),
                  SwitchListTile(
                    title: const Text('Bilibili'),
                    value: _platformBilibili,
                    onChanged: (value) {
                      setState(() {
                        _platformBilibili = value;
                        AppSettings.setDanmakuValue(
                            DanmakuKey.danmakuPlatformBilibili, value);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Gamer'),
                    value: _platformGamer,
                    onChanged: (value) {
                      setState(() {
                        _platformGamer = value;
                        AppSettings.setDanmakuValue(
                            DanmakuKey.danmakuPlatformGamer, value);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('弹弹Play'),
                    value: _platformDanDanPlay,
                    onChanged: (value) {
                      setState(() {
                        _platformDanDanPlay = value;
                        AppSettings.setDanmakuValue(
                            DanmakuKey.danmakuPlatformDanDanPlay, value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 简繁转换
                  Consumer(
                    builder: (context, ref, _) {
                      final danmakuChineseMode =
                          ref.watch(danmakuChineseModeProvider);
                      final colorScheme = Theme.of(context).colorScheme;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(l10n.danmakuChineseConversion),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: DropDownMenu<DanmakuChineseMode>(
                                items: DanmakuChineseMode.values,
                                selectedItem: danmakuChineseMode,
                                tooltip: l10n.danmakuChineseConversion,
                                onOpenedChanged: (isOpen) {
                                  if (_isChineseModeMenuOpen == isOpen) return;
                                  setState(
                                    () => _isChineseModeMenuOpen = isOpen,
                                  );
                                },
                                buttonBuilder: (context, _) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: colorScheme.outlineVariant,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _danmakuChineseModeLabel(
                                            danmakuChineseMode,
                                            l10n,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        AnimatedRotation(
                                          turns:
                                              _isChineseModeMenuOpen ? 0.5 : 0,
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          child: Icon(
                                            Icons.arrow_drop_down,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                itemBuilder: (context, mode, isSelected) {
                                  return Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        child: isSelected
                                            ? Icon(
                                                Icons.check,
                                                size: 18,
                                                color: colorScheme.primary,
                                              )
                                            : null,
                                      ),
                                      Text(
                                        _danmakuChineseModeLabel(mode, l10n),
                                      ),
                                    ],
                                  );
                                },
                                onSelected: (mode) {
                                  ref
                                      .read(
                                        danmakuChineseModeProvider.notifier,
                                      )
                                      .setMode(mode);
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 弹幕样式
                  _buildSectionTitle(l10n.danmakuStyle),
                  SwitchListTile(
                    title: Text(l10n.showBorder),
                    value: _border,
                    onChanged: (value) {
                      setState(() {
                        _border = value;
                        AppSettings.setDanmakuValue(
                            DanmakuKey.danmakuBorder, _border);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(l10n.showColor),
                    value: _danmakuColor,
                    onChanged: (value) {
                      setState(() {
                        _danmakuColor = value;
                        AppSettings.setDanmakuValue(
                            DanmakuKey.danmakuColor, _danmakuColor);
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(l10n.massiveMode),
                    value: _massiveMode,
                    onChanged: (value) {
                      setState(() {
                        _massiveMode = value;
                        AppSettings.setDanmakuValue(
                            DanmakuKey.danmakuMassiveMode, _massiveMode);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 弹幕速度
                  _buildSectionTitle(l10n.danmakuSpeedTitle),
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
                              l10n.danmakuSpeed(speedPercent),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
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
                                  AppSettings.setDanmakuValue(
                                      DanmakuKey.danmakuDuration, newDuration);
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
                  _buildSectionTitle(l10n.opacity),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${(_opacity * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
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
                              AppSettings.setDanmakuValue(
                                  DanmakuKey.danmakuOpacity, _opacity);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 字体大小
                  _buildSectionTitle(l10n.fontSize),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${_fontSize.toInt()}px',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
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
                              AppSettings.setDanmakuValue(
                                  DanmakuKey.danmakuFontSize, _fontSize);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 显示区域
                  _buildSectionTitle(l10n.displayArea),
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
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
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
                                  AppSettings.setDanmakuValue(
                                      DanmakuKey.danmakuArea, _danmakuArea);
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
            ),
          ),
        ),
      ),
    );
  }

  String _danmakuChineseModeLabel(
    DanmakuChineseMode mode,
    AppLocalizations l10n,
  ) {
    return switch (mode) {
      DanmakuChineseMode.none => l10n.danmakuChineseNone,
      DanmakuChineseMode.s2t => l10n.danmakuChineseToTraditional,
      DanmakuChineseMode.t2s => l10n.danmakuChineseToSimplified,
    };
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

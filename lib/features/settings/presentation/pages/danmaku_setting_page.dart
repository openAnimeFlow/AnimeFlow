import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_chinese_mode_provider.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/features/settings/presentation/providers/font_provider.dart';
import 'package:anime_flow/shared/models/font_item.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class DanmakuSettingPage extends ConsumerStatefulWidget {
  const DanmakuSettingPage({super.key});

  @override
  ConsumerState<DanmakuSettingPage> createState() => _DanmakuSettingPageState();
}

class _DanmakuSettingPageState extends ConsumerState<DanmakuSettingPage> {
  // 弹幕配置状态
  late bool _massiveMode;
  late bool _danmakuColor;
  late bool _hideTop;
  late bool _hideBottom;
  late bool _hideScroll;
  late bool _platformBilibili;
  late bool _platformGamer;
  late bool _platformDanDanPlay;
  bool _isChineseModeMenuOpen = false;
  bool _isFontMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _massiveMode = AppSettings.danmakuMassiveMode;
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
                  _buildSectionTitle(l10n.fontStroke),
                  _DanmakuSlider(
                    initialValue: AppSettings.danmakuStrokeWidth,
                    min: 0,
                    max: 3,
                    divisions: 6,
                    labelBuilder: (value) => '${value.toStringAsFixed(1)}px',
                    onChanged: (value) => AppSettings.setDanmakuValue(
                      DanmakuKey.danmakuBorder,
                      value,
                    ),
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

                  // 弹幕字体
                  Consumer(
                    builder: (context, ref, _) {
                      final downloadedFonts = ref
                          .watch(downloadedFontMetasProvider)
                          .values
                          .where((font) =>
                              ref.watch(fontDownloadProvider(font.id)).status ==
                              FontDownloadStatus.done)
                          .toList()
                        ..sort((a, b) => a.name.compareTo(b.name));
                      final selectedFamily =
                          ref.watch(danmakuFontFamilyProvider);
                      final options = [
                        const _DanmakuFontOption.project(),
                        ...downloadedFonts.map(_DanmakuFontOption.downloaded),
                      ];
                      final selected = options.firstWhere(
                        (option) => option.family == selectedFamily,
                        orElse: () => options.first,
                      );
                      final colorScheme = Theme.of(context).colorScheme;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(l10n.fontStyle),
                          SwitchListTile(
                            title: Text(l10n.customAppFont),
                            value: ref.watch(danmakuFontEnabledProvider),
                            onChanged: (enabled) {
                              ref
                                  .read(danmakuFontEnabledProvider.notifier)
                                  .setEnabled(enabled);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: DropDownMenu<_DanmakuFontOption>(
                                items: options,
                                selectedItem: selected,
                                tooltip: l10n.fontStyle,
                                onOpenedChanged: (isOpen) {
                                  if (_isFontMenuOpen == isOpen) return;
                                  setState(() => _isFontMenuOpen = isOpen);
                                },
                                buttonBuilder: (context, _) {
                                  return _buildFontMenuButton(
                                    context,
                                    selected.label(l10n),
                                    colorScheme,
                                  );
                                },
                                itemBuilder: (context, option, isSelected) {
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
                                      Expanded(
                                        child: Text(option.label(l10n)),
                                      ),
                                    ],
                                  );
                                },
                                onSelected: (option) {
                                  ref
                                      .read(danmakuFontFamilyProvider.notifier)
                                      .setFamily(option.family);
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // 弹幕速度
                  _buildSectionTitle(l10n.danmakuSpeedTitle),
                  _buildSpeedSlider(context, l10n),
                  const SizedBox(height: 16),

                  // 透明度
                  _buildSectionTitle(l10n.opacity),
                  _DanmakuSlider(
                    initialValue: AppSettings.danmakuOpacity,
                    min: 0.1,
                    max: 1.0,
                    labelBuilder: (value) => '${(value * 100).round()}%',
                    onChanged: (value) => AppSettings.setDanmakuValue(
                        DanmakuKey.danmakuOpacity, value),
                  ),
                  const SizedBox(height: 16),

                  // 字体大小
                  _buildSectionTitle(l10n.fontSize),
                  _DanmakuSlider(
                    initialValue: AppSettings.danmakuFontSize,
                    min: 12.0,
                    max: 30.0,
                    divisions: 18,
                    labelBuilder: (value) => '${value.toInt()}px',
                    onChanged: (value) => AppSettings.setDanmakuValue(
                        DanmakuKey.danmakuFontSize, value),
                  ),
                  const SizedBox(height: 16),

                  // 字体粗细
                  _buildSectionTitle(l10n.fontWeight),
                  _DanmakuSlider(
                    initialValue: AppSettings.danmakuFontWeight.toDouble(),
                    min: 0,
                    max: 8,
                    divisions: 8,
                    labelBuilder: (value) => '${(value.round() + 1) * 100}',
                    onChanged: (value) => AppSettings.setDanmakuValue(
                        DanmakuKey.danmakuFontWeight, value.round()),
                  ),
                  const SizedBox(height: 16),

                  // 显示区域
                  _buildSectionTitle(l10n.displayArea),
                  _buildAreaSlider(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedSlider(BuildContext context, AppLocalizations l10n) {
    const minDuration = 2.0;
    const maxDuration = 16.0;
    final currentDuration =
        AppSettings.danmakuDuration.clamp(minDuration, maxDuration);
    final initialSpeed =
        ((maxDuration - currentDuration) / (maxDuration - minDuration) * 100);
    return _DanmakuSlider(
      initialValue: initialSpeed,
      min: 0,
      max: 100,
      divisions: 20,
      labelBuilder: (value) => l10n.danmakuSpeed(value.round()),
      onChanged: (value) {
        final duration =
            maxDuration - (value / 100.0) * (maxDuration - minDuration);
        return AppSettings.setDanmakuValue(
            DanmakuKey.danmakuDuration, duration);
      },
    );
  }

  Widget _buildAreaSlider() {
    const fixedValues = [0.1, 0.25, 0.5, 0.75, 1.0];
    var initialIndex = fixedValues.indexWhere(
      (value) => (AppSettings.danmakuArea - value).abs() < 0.01,
    );
    if (initialIndex < 0) initialIndex = 0;
    return _DanmakuSlider(
      initialValue: initialIndex.toDouble(),
      min: 0,
      max: 4,
      divisions: 4,
      labelBuilder: (value) => '${(fixedValues[value.round()] * 100).toInt()}%',
      onChanged: (value) => AppSettings.setDanmakuValue(
        DanmakuKey.danmakuArea,
        fixedValues[value.round()],
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

  Widget _buildFontMenuButton(
    BuildContext context,
    String label,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: _isFontMenuOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.arrow_drop_down,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
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

class _DanmakuSlider extends StatefulWidget {
  const _DanmakuSlider({
    required this.initialValue,
    required this.min,
    required this.max,
    required this.labelBuilder,
    required this.onChanged,
    this.divisions,
  });

  final double initialValue;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value) labelBuilder;
  final Future<void> Function(double value) onChanged;

  @override
  State<_DanmakuSlider> createState() => _DanmakuSliderState();
}

class _DanmakuSliderState extends State<_DanmakuSlider> {
  late double _value = widget.initialValue.clamp(widget.min, widget.max);

  @override
  Widget build(BuildContext context) {
    final label = widget.labelBuilder(_value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 15),
          child: Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: label,
            onChanged: (value) {
              setState(() => _value = value);
              widget.onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _DanmakuFontOption {
  const _DanmakuFontOption.project() : font = null;

  const _DanmakuFontOption.downloaded(this.font);

  final FontItem? font;

  String? get family => font?.family;

  String label(AppLocalizations l10n) => font?.name ?? l10n.customAppFont;
}

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/danmaku/canvas_danmaku_adapter.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_chinese_mode_provider.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive_ce/hive.dart';

/// 弹幕设置弹窗
class DanmakuSettingDialog extends ConsumerStatefulWidget {
  const DanmakuSettingDialog({super.key});

  @override
  ConsumerState<DanmakuSettingDialog> createState() => _DanmakuSettingState();
}

/// 独立管理滑块状态，避免拖动时重建整个弹幕设置弹窗。
class _DanmakuOptionSlider extends StatefulWidget {
  const _DanmakuOptionSlider({
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
  final ValueChanged<double> onChanged;

  @override
  State<_DanmakuOptionSlider> createState() => _DanmakuOptionSliderState();
}

class _DanmakuOptionSliderState extends State<_DanmakuOptionSlider> {
  late double _value =
      widget.initialValue.clamp(widget.min, widget.max).toDouble();

  @override
  Widget build(BuildContext context) {
    final label = widget.labelBuilder(_value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 15),
          child: Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
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

class _DanmakuSettingState extends ConsumerState<DanmakuSettingDialog> {
  late final PlaySession playController;
  Box setting = Storage.setting;

  @override
  void initState() {
    super.initState();
    playController = ref.read(playSessionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final danmakuController = playController.danmaku.controller;
    if (danmakuController == null) {
      return const SizedBox.shrink();
    }
    final hideScroll = danmakuController.option.hideScroll;
    final hideTop = danmakuController.option.hideTop;
    final hideBottom = danmakuController.option.hideBottom;
    final danmakuChineseMode = ref.watch(danmakuChineseModeProvider);

    final fixedValues = [0.1, 0.25, 0.5, 0.75, 1.0];
    int currentIndex = 0;
    for (int i = 0; i < fixedValues.length; i++) {
      if ((danmakuController.option.area - fixedValues[i]).abs() < 0.01) {
        currentIndex = i;
        break;
      }
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.danmakuSettings,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      l10n.danmakuDisplayType,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  Text(l10n.danmakuChineseConversion),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: DropDownMenu<DanmakuChineseMode>(
                        items: DanmakuChineseMode.values,
                        selectedItem: danmakuChineseMode,
                        tooltip: l10n.danmakuChineseConversion,
                        buttonBuilder: (context, selected) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_danmakuChineseModeLabel(selected!, l10n)),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (context, mode, isSelected) => Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 18,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    )
                                  : null,
                            ),
                            Text(_danmakuChineseModeLabel(mode, l10n)),
                          ],
                        ),
                        onSelected: (mode) => ref
                            .read(danmakuChineseModeProvider.notifier)
                            .setMode(mode),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        children: [
                          InkWell(
                            onTap: () {
                              final newHideScroll = !hideScroll;
                              setState(() {
                                danmakuController.updateOption(
                                  danmakuController.option
                                      .copyWith(hideScroll: newHideScroll),
                                );
                                setting.put(
                                  DanmakuKey.danmakuHideScroll,
                                  newHideScroll,
                                );
                              });
                            },
                            child: Container(
                              width: 80,
                              height: 65,
                              decoration: BoxDecoration(
                                color: hideScroll
                                    ? Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.3)
                                    : Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              child: SvgPicture.asset(
                                'assets/icons/danmaku_scroll.svg',
                                colorFilter: const ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                              ),
                            ),
                          ),
                          Text(l10n.scrollingDanmaku)
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          InkWell(
                            onTap: () {
                              final newHideTop = !hideTop;
                              setState(() {
                                danmakuController.updateOption(
                                  danmakuController.option
                                      .copyWith(hideTop: newHideTop),
                                );
                                setting.put(
                                  DanmakuKey.danmakuHideTop,
                                  newHideTop,
                                );
                              });
                            },
                            child: Container(
                              width: 80,
                              height: 65,
                              decoration: BoxDecoration(
                                color: hideTop
                                    ? Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.3)
                                    : Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              child: SvgPicture.asset(
                                'assets/icons/danmaku_top.svg',
                                colorFilter: const ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                              ),
                            ),
                          ),
                          Text(l10n.topDanmaku)
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          InkWell(
                            onTap: () {
                              final newHideBottom = !hideBottom;
                              setState(() {
                                danmakuController.updateOption(
                                  danmakuController.option
                                      .copyWith(hideBottom: newHideBottom),
                                );
                                setting.put(
                                  DanmakuKey.danmakuHideBottom,
                                  newHideBottom,
                                );
                              });
                            },
                            child: Container(
                              width: 80,
                              height: 65,
                              decoration: BoxDecoration(
                                color: hideBottom
                                    ? Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.3)
                                    : Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              child: RotatedBox(
                                quarterTurns: 2,
                                child: SvgPicture.asset(
                                  'assets/icons/danmaku_top.svg',
                                  colorFilter: const ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ),
                          Text(l10n.bottomDanmaku)
                        ],
                      )
                    ],
                  ),
                  _buildSettingItem(
                    title: l10n.massiveMode,
                    value: danmakuController.option.massiveMode,
                    onChanged: (value) {
                      setState(() {
                        danmakuController.updateOption(
                          danmakuController.option.copyWith(massiveMode: value),
                        );
                        setting.put(DanmakuKey.danmakuMassiveMode, value);
                      });
                    },
                  ),
                  _DanmakuOptionSlider(
                    initialValue: danmakuController.option.strokeWidth,
                    min: 0,
                    max: 3,
                    divisions: 6,
                    labelBuilder: (value) =>
                        '${l10n.fontStroke}: ${value.toStringAsFixed(1)}px',
                    onChanged: (value) {
                      danmakuController.updateOption(
                        danmakuController.option.copyWith(strokeWidth: value),
                      );
                      setting.put(DanmakuKey.danmakuBorder, value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      // duration 范围：2.0 (最快) 到 16.0 (最慢)
                      // 速度百分比：0% (最慢) 到 100% (最快)
                      // 转换公式：speedPercent = (16.0 - duration) / (16.0 - 2.0) * 100
                      const minDuration = 2.0;
                      const maxDuration = 16.0;
                      final currentDuration = danmakuController.option.duration
                          .clamp(minDuration, maxDuration);
                      final speedPercent = ((maxDuration - currentDuration) /
                              (maxDuration - minDuration) *
                              100)
                          .round();
                      return _DanmakuOptionSlider(
                        initialValue: speedPercent.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        labelBuilder: (value) =>
                            l10n.danmakuSpeed(value.round()),
                        onChanged: (value) {
                          final newDuration = maxDuration -
                              (value / 100.0) * (maxDuration - minDuration);
                          danmakuController.updateOption(
                            danmakuController.option
                                .copyWith(duration: newDuration),
                          );
                          setting.put(DanmakuKey.danmakuDuration, newDuration);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _DanmakuOptionSlider(
                    initialValue: danmakuController.option.opacity,
                    min: 0.1,
                    max: 1,
                    labelBuilder: (value) =>
                        '${l10n.opacity}: ${(value * 100).round()}%',
                    onChanged: (value) {
                      danmakuController.updateOption(
                        danmakuController.option.copyWith(opacity: value),
                      );
                      setting.put(DanmakuKey.danmakuOpacity, value);
                    },
                  ),
                  const SizedBox(height: 8),
                  _DanmakuOptionSlider(
                    initialValue:
                        danmakuController.option.fontWeight.toDouble(),
                    min: 0,
                    max: 8,
                    divisions: 8,
                    labelBuilder: (value) =>
                        '${l10n.fontWeight}: ${(value.round() + 1) * 100}',
                    onChanged: (value) {
                      final fontWeight = value.round();
                      danmakuController.updateOption(
                        danmakuController.option
                            .copyWith(fontWeight: fontWeight),
                      );
                      setting.put(DanmakuKey.danmakuFontWeight, fontWeight);
                    },
                  ),
                  const SizedBox(height: 8),
                  _DanmakuOptionSlider(
                    initialValue: danmakuController.option.fontSize,
                    min: 12,
                    max: 30,
                    divisions: 18,
                    labelBuilder: (value) =>
                        '${l10n.fontSize}: ${value.toInt()}px',
                    onChanged: (value) {
                      danmakuController.updateOption(
                        danmakuController.option.copyWith(fontSize: value),
                      );
                      setting.put(DanmakuKey.danmakuFontSize, value);
                    },
                  ),
                  const SizedBox(height: 8),
                  _DanmakuOptionSlider(
                    initialValue: currentIndex.toDouble(),
                    min: 0,
                    max: 4,
                    divisions: 4,
                    labelBuilder: (value) =>
                        '${l10n.displayArea}: ${(fixedValues[value.round()] * 100).toInt()}%',
                    onChanged: (value) {
                      final index = value.round().clamp(0, 4);
                      danmakuController.updateOption(
                        danmakuController.option
                            .copyWith(area: fixedValues[index]),
                      );
                      setting.put(DanmakuKey.danmakuArea, fixedValues[index]);
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
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

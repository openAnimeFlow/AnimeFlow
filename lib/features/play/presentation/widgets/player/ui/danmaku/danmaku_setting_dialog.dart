import 'package:anime_flow/features/play/application/play_session.dart';
import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/setting/player_settings_sheet.dart';
import 'package:anime_flow/features/play/application/player_bindings.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/danmaku/canvas_danmaku_adapter.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_chinese_mode_provider.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

/// 弹幕设置弹窗
@Dependencies([playSession, PlayStateNotifier])
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
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

class _DanmakuTypeButton extends StatelessWidget {
  const _DanmakuTypeButton({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
    this.quarterTurns = 0,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 70,
                height: 49,
                child: RotatedBox(
                  quarterTurns: quarterTurns,
                  child: SvgPicture.asset(
                    asset,
                    colorFilter: ColorFilter.mode(
                      selected ? colors.primary : colors.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ExcludeSemantics(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DanmakuSettingState extends ConsumerState<DanmakuSettingDialog> {
  late final PlaySession playController;

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
    return PlayerSettingsSheet(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
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
          ),
          Flexible(
            child: SingleChildScrollView(
              primary: true,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.danmakuChineseConversion,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_danmakuChineseModeLabel(
                                      selected!, l10n)),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
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
                      )
                    ],
                  ),
                  // 弹幕显示类型
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
                  Wrap(
                    children: [
                      _DanmakuTypeButton(
                        label: l10n.scrollingDanmaku,
                        asset: AssetsPathConstants.danmakuScroll,
                        selected: !hideScroll,
                        onTap: () {
                          final hidden = !hideScroll;
                          setState(() {
                            danmakuController.updateOption(
                              danmakuController.option
                                  .copyWith(hideScroll: hidden),
                            );
                          });
                          AppSettings.setSetting(
                              DanmakuKey.danmakuHideScroll, hidden);
                        },
                      ),
                      _DanmakuTypeButton(
                        label: l10n.topDanmaku,
                        asset: AssetsPathConstants.danmakuTop,
                        selected: !hideTop,
                        onTap: () {
                          final hidden = !hideTop;
                          setState(() {
                            danmakuController.updateOption(
                              danmakuController.option
                                  .copyWith(hideTop: hidden),
                            );
                          });
                          AppSettings.setSetting(
                              DanmakuKey.danmakuHideTop, hidden);
                        },
                      ),
                      _DanmakuTypeButton(
                        label: l10n.bottomDanmaku,
                        asset: AssetsPathConstants.danmakuTop,
                        quarterTurns: 2,
                        selected: !hideBottom,
                        onTap: () {
                          final hidden = !hideBottom;
                          setState(() {
                            danmakuController.updateOption(
                              danmakuController.option
                                  .copyWith(hideBottom: hidden),
                            );
                          });
                          AppSettings.setSetting(
                              DanmakuKey.danmakuHideBottom, hidden);
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.massiveMode,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Switch(
                        value: danmakuController.option.massiveMode,
                        onChanged: (value) {
                          danmakuController.updateOption(
                            danmakuController.option
                                .copyWith(massiveMode: value),
                          );
                          AppSettings.setSetting(
                              DanmakuKey.danmakuMassiveMode, value);
                        },
                      )
                    ],
                  ),
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
                      AppSettings.setSetting(DanmakuKey.danmakuFontSize, value);
                    },
                  ),
                  const SizedBox(height: 8),
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
                      AppSettings.setSetting(DanmakuKey.danmakuBorder, value);
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
                          AppSettings.setSetting(
                              DanmakuKey.danmakuDuration, newDuration);
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
                      AppSettings.setSetting(DanmakuKey.danmakuOpacity, value);
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
                      AppSettings.setSetting(
                          DanmakuKey.danmakuFontWeight, fontWeight);
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
                      AppSettings.setSetting(
                          DanmakuKey.danmakuArea, fixedValues[index]);
                    },
                  ),
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
}

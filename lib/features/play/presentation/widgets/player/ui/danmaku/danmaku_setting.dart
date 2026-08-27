import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_chinese_mode_provider.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive_ce/hive.dart';

/// 弹幕设置弹窗
class DanmakuSetting extends ConsumerStatefulWidget {
  const DanmakuSetting({super.key});

  @override
  ConsumerState<DanmakuSetting> createState() => _DanmakuSettingState();
}

class _DanmakuSettingState extends ConsumerState<DanmakuSetting> {
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
    final danmakuController = playController.danmakuController;
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  Text(
                    l10n.danmakuChineseConversion,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<DanmakuChineseMode>(
                        segments: [
                          ButtonSegment(
                            value: DanmakuChineseMode.none,
                            label: Text(
                              l10n.danmakuChineseNone,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ButtonSegment(
                            value: DanmakuChineseMode.s2t,
                            label: Text(
                              l10n.danmakuChineseToTraditional,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ButtonSegment(
                            value: DanmakuChineseMode.t2s,
                            label: Text(
                              l10n.danmakuChineseToSimplified,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        selected: {danmakuChineseMode},
                        showSelectedIcon: false,
                        expandedInsets: EdgeInsets.zero,
                        onSelectionChanged: (selection) {
                          ref
                              .read(danmakuChineseModeProvider.notifier)
                              .setMode(selection.first);
                        },
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.danmakuSpeed(speedPercent),
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 5),
                              label: '$speedPercent%',
                              onChanged: (speedPercentValue) {
                                setState(() {
                                  // 将速度百分比转换回 duration
                                  // duration = maxDuration - speedPercent / 100 * (maxDuration - minDuration)
                                  final newDuration = maxDuration -
                                      (speedPercentValue / 100.0) *
                                          (maxDuration - minDuration);
                                  danmakuController.updateOption(
                                    danmakuController.option.copyWith(
                                      duration: newDuration,
                                    ),
                                  );
                                  setting.put(
                                      DanmakuKey.danmakuDuration, newDuration);
                                });
                              },
                            ),
                          )
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.opacity}: ${(danmakuController.option.opacity * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 15,
                        ),
                        child: Slider(
                          value: danmakuController.option.opacity,
                          min: 0.1,
                          max: 1.0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 5),
                          label:
                              '${(danmakuController.option.opacity * 100).round()}%',
                          onChanged: (value) {
                            setState(() {
                              danmakuController.updateOption(
                                danmakuController.option.copyWith(
                                  opacity: value,
                                ),
                              );
                              setting.put(DanmakuKey.danmakuOpacity, value);
                            });
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.fontSize}: ${danmakuController.option.fontSize.toInt()}px',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 15,
                        ),
                        child: Slider(
                          value: danmakuController.option.fontSize,
                          min: 12.0,
                          max: 30.0,
                          divisions: 18,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 5),
                          onChanged: (value) {
                            setState(() {
                              danmakuController.updateOption(
                                danmakuController.option
                                    .copyWith(fontSize: value),
                              );
                              setting.put(DanmakuKey.danmakuFontSize, value);
                            });
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.displayArea}: ${(danmakuController.option.area * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 5),
                          onChanged: (value) {
                            final index = value.round().clamp(0, 4);
                            setState(() {
                              danmakuController.updateOption(
                                danmakuController.option
                                    .copyWith(area: fixedValues[index]),
                              );
                              setting.put(
                                  DanmakuKey.danmakuArea, fixedValues[index]);
                            });
                          },
                        ),
                      )
                    ],
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

import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/core/utils/format_time_util.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';

class VideoSettingDialog extends ConsumerStatefulWidget {
  const VideoSettingDialog({super.key});

  @override
  ConsumerState<VideoSettingDialog> createState() => _VideoSettingState();
}

class _VideoSettingState extends ConsumerState<VideoSettingDialog> {
  bool isExpandedTime = false;
  int selectedHours = 0; // 选中的小时
  int selectedMinutes = 0; // 选中的分钟

  late final PlaySession playController;

  // 小时列表 (0-23)
  final List<int> _hours = List.generate(24, (index) => index);

  // 分钟列表 (0-59)
  final List<int> _minutes = List.generate(60, (index) => index);

  // 滚动控制器
  final FixedExtentScrollController _hoursController =
      FixedExtentScrollController();
  final FixedExtentScrollController _minutesController =
      FixedExtentScrollController();

  @override
  void initState() {
    super.initState();
    playController = ref.read(playSessionProvider);
    // 延迟设置初始位置，确保列表已构建
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hoursController.jumpToItem(selectedHours);
      _minutesController.jumpToItem(selectedMinutes);
    });
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  /// 格式化时长显示
  String _formatSelectedTime() {
    final l10n = AppLocalizations.of(context);
    if (selectedHours == 0 && selectedMinutes == 0) {
      return l10n.close;
    }
    if (selectedHours == 0) {
      return l10n.minutesUnit(selectedMinutes);
    }
    if (selectedMinutes == 0) {
      return l10n.hoursUnit(selectedHours);
    }
    return l10n.hoursMinutesUnit(selectedHours, selectedMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentKernel = ref.watch(
      playStateProvider.select((state) => state.kernel),
    );
    final switchingKernel = ref.watch(
      playStateProvider.select((state) => state.switchingKernel),
    );
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Theme.of(context).cardColor,
        child: SizedBox(
          width: LayoutConstant.playContentWidth,
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题栏
                  Row(
                    children: [
                      Text(
                        l10n.videoSettingsTitle,
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  // 定时关闭视频UI
                  InkWell(
                    onTap: () {
                      setState(() {
                        isExpandedTime = !isExpandedTime;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const Icon(Icons.slow_motion_video_outlined,
                              size: 25),
                          const SizedBox(height: 5),
                          Consumer(
                            builder: (context, ref, child) {
                              final scheduledStopDuration = ref.watch(
                                playStateProvider.select(
                                    (state) => state.scheduledStopDuration),
                              );
                              return Text(
                                scheduledStopDuration == 0
                                    ? l10n.scheduledOff
                                    : FormatTimeUtil.formatDuration(Duration(
                                        seconds: scheduledStopDuration)),
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.none,
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.color,
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isExpandedTime ? null : 0,
                    child: isExpandedTime
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 显示选中的时间
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _formatSelectedTime(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.none,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        final totalSeconds =
                                            selectedHours * 3600 +
                                                selectedMinutes * 60;

                                        if (totalSeconds > 0) {
                                          playController.stopPlaying(
                                            duration:
                                                Duration(seconds: totalSeconds),
                                          );
                                        } else {
                                          // 如果选择的是0，取消定时停止
                                          playController.cancelScheduledStop();
                                        }

                                        setState(() {
                                          isExpandedTime = false;
                                        });
                                        // VideoSetting 通过 showGeneralDialog 打开，不是 GoRouter 路由页。
                                        // 里应使用 Navigator.of(context).pop() 关闭
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        l10n.confirm,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 滚动时间选择器
                              Stack(
                                children: [
                                  SizedBox(
                                    height: 150,
                                    child: Row(
                                      children: [
                                        // 小时选择器
                                        Expanded(
                                          child:
                                              ListWheelScrollView.useDelegate(
                                            controller: _hoursController,
                                            itemExtent: 40,
                                            physics:
                                                const FixedExtentScrollPhysics(),
                                            onSelectedItemChanged: (index) {
                                              setState(() {
                                                selectedHours = _hours[index];
                                              });
                                            },
                                            childDelegate:
                                                ListWheelChildBuilderDelegate(
                                              builder: (context, index) {
                                                if (index >= _hours.length) {
                                                  return null;
                                                }
                                                final hour = _hours[index];
                                                final isSelected =
                                                    selectedHours == hour;
                                                return Center(
                                                  child: Text(
                                                    hour.toString(),
                                                    style: TextStyle(
                                                      fontSize:
                                                          isSelected ? 20 : 16,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: isSelected
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                          : Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.color,
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                  ),
                                                );
                                              },
                                              childCount: _hours.length,
                                            ),
                                          ),
                                        ),
                                        // 分钟选择器
                                        Expanded(
                                          child:
                                              ListWheelScrollView.useDelegate(
                                            controller: _minutesController,
                                            itemExtent: 40,
                                            physics:
                                                const FixedExtentScrollPhysics(),
                                            onSelectedItemChanged: (index) {
                                              setState(() {
                                                selectedMinutes =
                                                    _minutes[index];
                                              });
                                            },
                                            childDelegate:
                                                ListWheelChildBuilderDelegate(
                                              builder: (context, index) {
                                                if (index >= _minutes.length) {
                                                  return null;
                                                }
                                                final minute = _minutes[index];
                                                final isSelected =
                                                    selectedMinutes == minute;
                                                return Center(
                                                  child: Text(
                                                    minute.toString(),
                                                    style: TextStyle(
                                                      fontSize:
                                                          isSelected ? 20 : 16,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: isSelected
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                          : Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.color,
                                                      decoration:
                                                          TextDecoration.none,
                                                    ),
                                                  ),
                                                );
                                              },
                                              childCount: _minutes.length,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  _buildPlayerKernelSetting(
                    context,
                    currentKernel,
                    switchingKernel,
                  ),
                  const Divider(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerKernelSetting(
    BuildContext context,
    PlayerKernel currentKernel,
    bool switchingKernel,
  ) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        spacing: 8,
        children: [
          const Icon(Icons.video_settings_outlined),
          Text(
            l10n.playerKernel,
            style: const TextStyle(decoration: TextDecoration.none),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switchingKernel
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : DropDownMenu<PlayerKernel>(
                    key: const ValueKey('select-player-kernel'),
                    items: PlayerKernel.values,
                    selectedItem: currentKernel,
                    tooltip: l10n.selectPlayerKernel,
                    offset: const Offset(0, 44),
                    buttonBuilder: (context, selectedKernel) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_kernelLabel(selectedKernel ?? currentKernel)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      );
                    },
                    itemBuilder: (context, kernel, isSelected) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_kernelLabel(kernel)),
                          if (isSelected) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.check, size: 18),
                          ],
                        ],
                      );
                    },
                    onSelected: (kernel) async {
                      if (switchingKernel || kernel == currentKernel) return;
                      final switched = await playController.switchKernel(kernel);
                      if (!context.mounted || switched) return;
                      NotificationToast.show(l10n.playerKernelSwitchFailed);
                    },
                  ),
          )
        ],
      ),
    );
  }

  String _kernelLabel(PlayerKernel kernel) {
    return switch (kernel) {
      PlayerKernel.mediaKit => AppLocalizations.of(context).mediaKit,
      PlayerKernel.fvp => AppLocalizations.of(context).fvp,
    };
  }
}

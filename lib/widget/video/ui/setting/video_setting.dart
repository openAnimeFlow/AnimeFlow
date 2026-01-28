import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoSetting extends StatefulWidget {
  const VideoSetting({super.key});

  @override
  State<VideoSetting> createState() => _VideoSettingState();
}

class _VideoSettingState extends State<VideoSetting> {
  bool isExpandedTime = false;
  int selectedHours = 0; // 选中的小时
  int selectedMinutes = 0; // 选中的分钟

  late VideoStateController videoStateController;

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
    videoStateController = Get.find<VideoStateController>();
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
    if (selectedHours == 0 && selectedMinutes == 0) {
      return '关闭';
    }
    if (selectedHours == 0) {
      return '$selectedMinutes分钟';
    }
    if (selectedMinutes == 0) {
      return '$selectedHours小时';
    }
    return '$selectedHours小时$selectedMinutes分钟';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: PlayLayoutConstant.playContentWidth,
          height: MediaQuery.of(context).size.height,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题栏
                  Row(
                    children: [
                      const Text(
                        '视频设置',
                        style: TextStyle(
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
                          Obx(
                                () => Text(
                              videoStateController
                                  .scheduledStopDuration.value ==
                                  0
                                  ? '定时关闭'
                                  : FormatTimeUtil.formatScheduledTime(videoStateController
                                  .scheduledStopDuration.value),
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.color,
                              ),
                            ),
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
                                    videoStateController.stopPlaying(
                                      duration:
                                      Duration(seconds: totalSeconds),
                                    );
                                  } else {
                                    // 如果选择的是0，取消定时停止
                                    videoStateController
                                        .cancelScheduledStop();
                                  }

                                  setState(() {
                                    isExpandedTime = false;
                                  });
                                  Get.back();
                                },
                                child: Text(
                                  '确定',
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
                  Text(
                    '更多设置正在施工中...',
                    style: TextStyle(
                      fontSize: 20,
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

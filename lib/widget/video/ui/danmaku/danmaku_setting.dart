import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

/// 弹幕设置弹窗
class DanmakuSetting extends StatefulWidget {
  const DanmakuSetting({super.key});

  @override
  State<DanmakuSetting> createState() => _DanmakuSettingState();
}

class _DanmakuSettingState extends State<DanmakuSetting> {
  late PlayController playController;

  // 弹幕设置状态
  bool _border = true;
  double _opacity = 1.0;
  bool _hideTop = false;
  bool _hideBottom = false;
  bool _hideScroll = false;
  bool _massiveMode = false;
  bool _danmakuColor = true;

  @override
  void initState() {
    super.initState();
    playController = Get.find<PlayController>();
  }

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
              '弹幕显示类型',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
          Obx(() {
            final scroll = playController.danmakuScroll.value;
            final hideTop = playController.danmakuHideTop.value;
            final hideBottom = playController.danmakuHideBottom.value;
            return Row(
              children: [
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        playController.setScrollDanmaku(scroll ? false : true);
                      },
                      child: Container(
                        width: 80,
                        height: 65,
                        decoration: BoxDecoration(
                          color: scroll
                              ? Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.3)
                              : Theme.of(context).colorScheme.primaryContainer,
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
                    const Text('滚动弹幕')
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        playController.setTopDanmaku(hideTop ? false : true);
                      },
                      child: Container(
                        width: 80,
                        height: 65,
                        decoration: BoxDecoration(
                          color: hideTop
                              ? Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.3)
                              : Theme.of(context).colorScheme.primaryContainer,
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
                    const Text('顶部弹幕')
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        playController
                            .setBottomDanmaku(hideBottom ? false : true);
                      },
                      child: Container(
                        width: 80,
                        height: 65,
                        decoration: BoxDecoration(
                          color: hideBottom
                              ? Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.3)
                              : Theme.of(context).colorScheme.primaryContainer,
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
                    const Text('底部弹幕')
                  ],
                )
              ],
            );
          }),
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
            title: '密集模式',
            value: _massiveMode,
            onChanged: (value) {
              setState(() {
                _massiveMode = value;
              });
            },
          ),
          const SizedBox(height: 16),

          Column(
            children: [
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
            ],
          ),

          const SizedBox(height: 8),
          Obx(() => Column(
                children: [
                  Text(
                    '字体大小: ${playController.danmakuFontSize.value.toInt()}px',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Slider(
                    value: playController.danmakuFontSize.value,
                    min: 12.0,
                    max: 30.0,
                    divisions: 18,
                    onChanged: (value) {
                      playController.setDanmakuFontSize(value);
                    },
                  ),
                ],
              )),
          const SizedBox(height: 8),
          Obx(() {
            final fixedValues = [0.1, 0.25, 0.5, 0.75, 1.0];
            int currentIndex = 0;
            for (int i = 0; i < fixedValues.length; i++) {
              if ((playController.danmakuArea.value - fixedValues[i]).abs() <
                  0.01) {
                currentIndex = i;
                break;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '显示区域: ${(playController.danmakuArea.value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Slider(
                  value: currentIndex.toDouble(),
                  min: 0.0,
                  max: 4.0,
                  divisions: 4,
                  onChanged: (value) {
                    final index = value.round().clamp(0, 4);
                    playController.setDanmakuArea(fixedValues[index]);
                  },
                ),
              ],
            );
          }),
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

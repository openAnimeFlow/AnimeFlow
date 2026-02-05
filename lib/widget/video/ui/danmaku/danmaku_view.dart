import 'dart:async';
import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class DanmakuView extends StatefulWidget {
  const DanmakuView({super.key});

  @override
  State<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends State<DanmakuView>
    with AutomaticKeepAliveClientMixin {
  Box setting = Storage.setting;
  late VideoStateController videoStateController;
  late PlayController playController;
  late EpisodesState episodesState;
  Timer? _danmakuTimer;
  Worker? _playingWorker;

  // 弹幕配置
  late bool _border;
  late double _opacity;
  late double _fontSize;
  late double _danmakuArea;
  late bool _hideTop;
  late bool _hideBottom;
  late bool _hideScroll;
  late bool _massiveMode;
  late bool _danmakuColor;
  late double _danmakuDuration;
  late double _danmakuLineHeight;
  late int _danmakuFontWeight;
  late bool _danmakuUseSystemFont;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    videoStateController = Get.find<VideoStateController>();
    playController = Get.find<PlayController>();
    episodesState = Get.find<EpisodesState>();

    // 初始化弹幕配置
    _border = setting.get(DanmakuKey.danmakuBorder, defaultValue: true);
    _opacity = setting.get(DanmakuKey.danmakuOpacity, defaultValue: 1.0);
    _fontSize = setting.get(DanmakuKey.danmakuFontSize, defaultValue: 16.0);
    _danmakuArea = setting.get(DanmakuKey.danmakuArea, defaultValue: 0.25);
    _hideTop = setting.get(DanmakuKey.danmakuHideTop, defaultValue: false);
    _hideBottom = setting.get(DanmakuKey.danmakuHideBottom, defaultValue: false);
    _hideScroll = setting.get(DanmakuKey.danmakuHideScroll, defaultValue: false);
    _massiveMode = setting.get(DanmakuKey.danmakuMassiveMode, defaultValue: false);
    _danmakuColor = setting.get(DanmakuKey.danmakuColor, defaultValue: true);
    _danmakuDuration = setting.get(DanmakuKey.danmakuDuration, defaultValue: 8.0);
    _danmakuLineHeight = setting.get(DanmakuKey.danmakuLineHeight, defaultValue: 1.6);
    _danmakuFontWeight = setting.get(DanmakuKey.danmakuFontWeight, defaultValue: 4);
    _danmakuUseSystemFont = setting.get(DanmakuKey.danmakuUseSystemFont, defaultValue: false);

    // 启动弹幕定时器
    _startDanmakuTimer();

    // 监听倍速变化，更新弹幕速度
    ever(videoStateController.rate, (rate) {
      // 倍速变化时，更新弹幕速度需要在 DanmakuScreen 重建时更新
      setState(() {});
    });

    //监听集数切换
    ever(episodesState.episodeIndex, (int episode) {
      if (episode > 0) {
        // 清空之前的弹幕
        playController.removeDanmaku();
      }
    });

    // 监听播放状态变化，控制弹幕暂停/恢复
    _playingWorker = ever(videoStateController.playing, (playing) {
      if (mounted) {
        try {
          if (playing) {
            playController.danmakuController.resume();
          } else {
            playController.danmakuController.pause();
          }
        } catch (_) {}
      }
    });
  }

  void _startDanmakuTimer() {
    _danmakuTimer?.cancel();
    _danmakuTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final currentPosition = videoStateController.position.value;
      final playing = videoStateController.playing.value;

      // 只有在播放时才添加弹幕
      if (currentPosition.inMicroseconds != 0 &&
          playing &&
          playController.danmakuOn.value) {
        final currentSecond = currentPosition.inSeconds;
        final danmakus = playController.danDanmakus[currentSecond];

        if (danmakus != null && danmakus.isNotEmpty) {
          // 按索引延迟添加弹幕
          danmakus.asMap().forEach((idx, danmaku) {
            Future.delayed(
              Duration(
                milliseconds: idx * 1000 ~/ danmakus.length,
              ),
              () {
                if (!mounted ||
                    !videoStateController.playing.value ||
                    !playController.danmakuOn.value) {
                  return;
                }

                // 检查平台是否被隐藏
                final regex = RegExp(r'\[([^\]]+)\]');
                final match = regex.firstMatch(danmaku.source);
                final platform = match?.group(1) ?? '弹弹Play';
                if (playController.isPlatformHidden(platform)) {
                  return; // 如果平台被隐藏，不添加弹幕
                }

                // 转换弹幕类型
                DanmakuItemType danmakuType;
                if (danmaku.type == 4) {
                  danmakuType = DanmakuItemType.bottom;
                } else if (danmaku.type == 5) {
                  danmakuType = DanmakuItemType.top;
                } else {
                  danmakuType = DanmakuItemType.scroll;
                }

                // 处理颜色
                Color danmakuColor = danmaku.color;
                if (!_danmakuColor) {
                  danmakuColor = Colors.white;
                }

                // 添加弹幕
                playController.danmakuController.addDanmaku(
                  DanmakuContentItem(
                    danmaku.message,
                    color: danmakuColor,
                    type: danmakuType,
                  ),
                );
              },
            );
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _danmakuTimer?.cancel();
    _playingWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return IgnorePointer(
      // 弹幕层不拦截点击事件，让播放器控件可以正常交互
      ignoring: true,
      child: DanmakuScreen(
        createdController: (DanmakuController controller) {
          // 更新全局控制器引用
          playController.danmakuController = controller;
          // 应用保存的设置
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              controller.updateOption(
                controller.option.copyWith(
                  fontSize: _fontSize,
                  area: _danmakuArea,
                  opacity: _opacity,
                  hideScroll: _hideScroll,
                  hideTop: _hideTop,
                  hideBottom: _hideBottom,
                  duration: _danmakuDuration / videoStateController.rate.value,
                  massiveMode: _massiveMode,
                ),
              );
            } catch (_) {
              // 如果控制器未初始化，忽略错误
            }
          });
        },
        option: DanmakuOption(
          hideTop: _hideTop,
          hideScroll: _hideScroll,
          hideBottom: _hideBottom,
          area: _danmakuArea,
          opacity: _opacity,
          fontSize: _fontSize,
          duration: _danmakuDuration / videoStateController.rate.value,
          lineHeight: _danmakuLineHeight,
          strokeWidth: _border ? 1.5 : 0.0,
          fontWeight: _danmakuFontWeight,
          massiveMode: _massiveMode,
          fontFamily: _danmakuUseSystemFont ? null : null, // 可以设置自定义字体
        ),
      ),
    );
  }
}

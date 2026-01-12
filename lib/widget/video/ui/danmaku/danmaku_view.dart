import 'dart:async';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DanmakuView extends StatefulWidget {
  const DanmakuView({super.key});

  @override
  State<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends State<DanmakuView> with AutomaticKeepAliveClientMixin{
  late VideoStateController videoStateController;
  late PlayController playPageController;
  Timer? _danmakuTimer;

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
    playPageController = Get.find<PlayController>();
    // 初始化弹幕配置（可以从设置中读取）
    _border = true;
    _opacity = 1.0;
    _fontSize = Utils.isMobile ? 16.0 : 25.0;
    _danmakuArea = 1.0;
    _hideTop = false;
    _hideBottom = false;
    _hideScroll = false;
    _massiveMode = false;
    _danmakuColor = true;
    _danmakuDuration = 8.0;
    _danmakuLineHeight = 1.6;
    _danmakuFontWeight = 4;
    _danmakuUseSystemFont = false;
    
    // 启动弹幕定时器
    _startDanmakuTimer();
    
    // 监听倍速变化，更新弹幕速度
    ever(videoStateController.rate, (rate) {
      // 倍速变化时，更新弹幕速度需要在 DanmakuScreen 重建时更新
      setState(() {});
    });
  }

  void _startDanmakuTimer() {
    _danmakuTimer?.cancel();
    _danmakuTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      final currentPosition = videoStateController.position.value;
      final playing = videoStateController.playing.value;
      
      // 只有在播放时才添加弹幕
      if (currentPosition.inMicroseconds != 0 && playing && playPageController.danmakuOn.value) {
        final currentSecond = currentPosition.inSeconds;
        final danmakus = playPageController.danDanmakus[currentSecond];
        
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
                    !playPageController.danmakuOn.value) {
                  return;
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
                playPageController.danmakuController.addDanmaku(
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
          playPageController.danmakuController = controller;
          // 如果需要更新弹幕速度，可以在这里添加
          // WidgetsBinding.instance.addPostFrameCallback((_) {
          //   // 更新弹幕速度的逻辑
          // });
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

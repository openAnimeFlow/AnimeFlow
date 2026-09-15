import 'dart:async';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DanmakuView extends ConsumerStatefulWidget {
  const DanmakuView({super.key});

  @override
  ConsumerState<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends ConsumerState<DanmakuView>
    with AutomaticKeepAliveClientMixin {
  late final PlaySession playController;
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
    playController = ref.read(playSessionProvider);

    // 初始化弹幕配置
    _border = AppSettings.danmakuBorder;
    _opacity = AppSettings.danmakuOpacity;
    _fontSize = AppSettings.danmakuFontSize;
    _danmakuArea = AppSettings.danmakuArea;
    _hideTop = AppSettings.danmakuHideTop;
    _hideBottom = AppSettings.danmakuHideBottom;
    _hideScroll = AppSettings.danmakuHideScroll;
    _massiveMode = AppSettings.danmakuMassiveMode;
    _danmakuColor = AppSettings.danmakuColor;
    _danmakuDuration = AppSettings.danmakuDuration;
    _danmakuLineHeight = AppSettings.danmakuLineHeight;
    _danmakuFontWeight = AppSettings.danmakuFontWeight;
    _danmakuUseSystemFont = AppSettings.danmakuUseSystemFont;

    // 启动弹幕定时器
    _startDanmakuTimer();
  }

  void _startDanmakuTimer() {
    _danmakuTimer?.cancel();
    _danmakuTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final playState = ref.read(playStateProvider);
      final currentPosition = playState.position;
      final playing = playState.playing;

      // 只有在播放时才添加弹幕
      if (currentPosition.inMicroseconds != 0 &&
          playing &&
          playState.danmakuOn) {
        final currentSecond = currentPosition.inSeconds;
        final danmakus = playState.danDanmakus[currentSecond];
        final danmakuEpoch = playState.danmakuEpoch;

        if (danmakus != null && danmakus.isNotEmpty) {
          // 按索引延迟添加弹幕
          danmakus.asMap().forEach((idx, danmaku) {
            Future.delayed(
              Duration(
                milliseconds: idx * 1000 ~/ danmakus.length,
              ),
              () {
                if (!mounted ||
                    danmakuEpoch != ref.read(playStateProvider).danmakuEpoch ||
                    !ref.read(playStateProvider).playing ||
                    !ref.read(playStateProvider).danmakuOn) {
                  return;
                }

                // 本人弹幕不参与平台隐藏
                // if (!danmaku.selfSend) {
                final regex = RegExp(r'\[([^\]]+)\]');
                final match = regex.firstMatch(danmaku.source);
                final platform = match?.group(1) ?? '弹弹Play';
                if (playController.isPlatformHidden(platform)) {
                  return;
                }
                // }

                // 处理颜色
                if (!_danmakuColor) {
                  danmaku.color = Colors.white;
                }

                // 添加弹幕
                playController.addDanDanmaku(
                  danmaku,
                  ref.read(currentUserInfoProvider).value?.id,
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
    final rate = ref.watch(
      playStateProvider.select((state) => state.rate),
    );
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
                  duration: _danmakuDuration / rate,
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
          duration: _danmakuDuration / rate,
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

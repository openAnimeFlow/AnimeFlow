import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'canvas_danmaku_adapter.dart';

class DanmakuView extends ConsumerStatefulWidget {
  const DanmakuView({super.key});

  @override
  ConsumerState<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends ConsumerState<DanmakuView>
    with AutomaticKeepAliveClientMixin {
  late final PlaySession playController;

  // 弹幕配置
  late bool _border;
  late double _opacity;
  late double _fontSize;
  late double _danmakuArea;
  late bool _hideTop;
  late bool _hideBottom;
  late bool _hideScroll;
  late bool _massiveMode;
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
    _danmakuDuration = AppSettings.danmakuDuration;
    _danmakuLineHeight = AppSettings.danmakuLineHeight;
    _danmakuFontWeight = AppSettings.danmakuFontWeight;
    _danmakuUseSystemFont = AppSettings.danmakuUseSystemFont;
  }

  @override
  void dispose() {
    if (identical(playController.danmaku.canvas, _adapter)) {
      playController.danmaku.canvas = null;
    }
    super.dispose();
  }

  CanvasDanmakuAdapter? _adapter;

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
          _adapter = CanvasDanmakuAdapter(controller);
          playController.danmaku.canvas = _adapter;
          // 应用保存的设置
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !identical(_adapter?.controller, controller)) {
              return;
            }
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

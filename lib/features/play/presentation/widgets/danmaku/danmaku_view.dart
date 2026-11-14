import 'package:anime_flow/features/play/application/play_session.dart';
import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/app/theme/theme_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/core/settings/danmaku_font_provider.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'canvas_danmaku_adapter.dart';

@Dependencies([playSession, PlayStateNotifier])
class DanmakuView extends ConsumerStatefulWidget {
  const DanmakuView({super.key});

  @override
  ConsumerState<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends ConsumerState<DanmakuView>
    with AutomaticKeepAliveClientMixin {
  late final PlaySession playSession;

  // 弹幕配置
  late double _strokeWidth;
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    playSession = ref.read(playSessionProvider);

    // 初始化弹幕配置
    _strokeWidth = ref.read(playPreferencesProvider).danmakuStrokeWidth;
    _opacity = ref.read(playPreferencesProvider).danmakuOpacity;
    _fontSize = ref.read(playPreferencesProvider).danmakuFontSize;
    _danmakuArea = ref.read(playPreferencesProvider).danmakuArea;
    _hideTop = ref.read(playPreferencesProvider).danmakuHideTop;
    _hideBottom = ref.read(playPreferencesProvider).danmakuHideBottom;
    _hideScroll = ref.read(playPreferencesProvider).danmakuHideScroll;
    _massiveMode = ref.read(playPreferencesProvider).danmakuMassiveMode;
    _danmakuDuration = ref.read(playPreferencesProvider).danmakuDuration;
    _danmakuLineHeight = ref.read(playPreferencesProvider).danmakuLineHeight;
    _danmakuFontWeight = ref.read(playPreferencesProvider).danmakuFontWeight;
  }

  @override
  void dispose() {
    if (identical(playSession.danmaku.canvas, _adapter)) {
      playSession.danmaku.canvas = null;
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
    final useFont = ref.watch(danmakuFontEnabledProvider);
    final projectFontFamily = useFont
        ? ref.watch(danmakuFontFamilyProvider) ??
            ref.watch(themeProvider.select((state) => state.fontFamily))
        : null;
    return IgnorePointer(
      // 弹幕层不拦截点击事件，让播放器控件可以正常交互
      ignoring: true,
      child: DanmakuScreen(
        createdController: (DanmakuController controller) {
          // 更新全局控制器引用
          _adapter = CanvasDanmakuAdapter(controller);
          playSession.danmaku.canvas = _adapter;
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
                  fontFamily: projectFontFamily,
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
          strokeWidth: _strokeWidth,
          fontWeight: _danmakuFontWeight,
          massiveMode: _massiveMode,
          fontFamily: projectFontFamily,
        ),
      ),
    );
  }
}

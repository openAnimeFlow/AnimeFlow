import 'dart:async';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/controllers/shaders/shaders_provider.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

/// 播放器 UI / 弹幕相关状态（与 [PlayController] 字段对齐，供 Riverpod 使用）
class PlayState {
  const PlayState({
    this.superResolutionType = 0,
    this.isWideScreen = false,
    this.isContentExpanded = true,
    this.isFullscreen = false,
    this.danDanmakus = const <int, List<Danmaku>>{},
    this.danmakuOn = true,
    this.hiddenPlatforms = const <String>{},
  });

  /// 超分：0 初始；1 关；2 效率；3 质量（与 [PlayNotifier.setShader] 一致）
  final int superResolutionType;
  final bool isWideScreen;
  final bool isContentExpanded;
  final bool isFullscreen;
  final Map<int, List<Danmaku>> danDanmakus;
  final bool danmakuOn;
  final Set<String> hiddenPlatforms;

  PlayState copyWith({
    int? superResolutionType,
    bool? isWideScreen,
    bool? isContentExpanded,
    bool? isFullscreen,
    Map<int, List<Danmaku>>? danDanmakus,
    bool? danmakuOn,
    Set<String>? hiddenPlatforms,
  }) {
    return PlayState(
      superResolutionType: superResolutionType ?? this.superResolutionType,
      isWideScreen: isWideScreen ?? this.isWideScreen,
      isContentExpanded: isContentExpanded ?? this.isContentExpanded,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      danDanmakus: danDanmakus ?? this.danDanmakus,
      danmakuOn: danmakuOn ?? this.danmakuOn,
      hiddenPlatforms: hiddenPlatforms ?? this.hiddenPlatforms,
    );
  }
}

Set<String> _hiddenPlatformsFromStorage() {
  final Box setting = Storage.setting;
  final platformBilibili =
      setting.get(DanmakuKey.danmakuPlatformBilibili, defaultValue: true) as bool;
  final platformGamer =
      setting.get(DanmakuKey.danmakuPlatformGamer, defaultValue: true) as bool;
  final platformDanDanPlay =
      setting.get(DanmakuKey.danmakuPlatformDanDanPlay, defaultValue: true)
          as bool;

  const platformNameBilibili = 'BiliBili';
  const platformNameGamer = 'Gamer';
  const platformNameDanDanPlay = '弹弹Play';

  final hidden = <String>{};
  if (!platformBilibili) hidden.add(platformNameBilibili);
  if (!platformGamer) hidden.add(platformNameGamer);
  if (!platformDanDanPlay) hidden.add(platformNameDanDanPlay);
  return hidden;
}

/// Riverpod 版播放控制逻辑，与 [PlayController] 行为对齐。
///
/// 使用方式：`ref.watch(playProvider)` / `ref.read(playProvider.notifier)`。
/// [DanmakuController] 由弹幕组件创建后调用 [attachDanmakuController]。
final playProvider = NotifierProvider<PlayNotifier, PlayState>(PlayNotifier.new);

class PlayNotifier extends Notifier<PlayState> {
  DanmakuController? _danmakuController;
  Timer? _saveSettingsTimer;

  DanmakuController? get danmakuController => _danmakuController;

  set danmakuController(DanmakuController? value) => _danmakuController = value;

  void attachDanmakuController(DanmakuController controller) {
    _danmakuController = controller;
  }

  @override
  PlayState build() {
    ref.onDispose(() {
      _saveSettingsTimer?.cancel();
    });
    return PlayState(hiddenPlatforms: _hiddenPlatformsFromStorage());
  }

  /// 从存储同步平台显示/隐藏（与 GetX 版一致）
  void syncPlatformVisibilityFromStorage() {
    state = state.copyWith(hiddenPlatforms: _hiddenPlatformsFromStorage());
    try {
      _danmakuController?.clear();
    } catch (_) {}
  }

  /// 宽屏切换
  void updateIsWideScreen(bool value) {
    if (state.isWideScreen != value) {
      state = state.copyWith(isWideScreen: value);
    }
  }

  void toggleContentExpanded() {
    state = state.copyWith(isContentExpanded: !state.isContentExpanded);
  }

  void enterFullScreen() {
    state = state.copyWith(isFullscreen: true);
    SystemUtil.enterFullScreen();
  }

  void exitFullScreen() {
    state = state.copyWith(isFullscreen: false);
    SystemUtil.exitFullScreen();
  }

  void toggleFullScreen() {
    if (state.isFullscreen) {
      exitFullScreen();
    } else {
      enterFullScreen();
    }
  }

  /// 检测桌面端全屏状态
  Future<void> checkDesktopFullscreen() async {
    if (SystemUtil.isDesktop) {
      state = state.copyWith(isFullscreen: await windowManager.isFullScreen());
    }
  }

  void handleFullscreenChange() {
    try {
      _danmakuController?.clear();
    } catch (_) {}
  }

  void addDanmaku(List<Danmaku> danmaku) {
    final map = <int, List<Danmaku>>{};
    for (final item in danmaku) {
      final second = item.time.toInt();
      map.putIfAbsent(second, () => []).add(item);
    }
    state = state.copyWith(danDanmakus: map);
  }

  void removeDanmaku() {
    _danmakuController?.clear();
    state = state.copyWith(danDanmakus: {});
  }

  void toggleDanmaku() {
    final next = !state.danmakuOn;
    state = state.copyWith(danmakuOn: next);
    Storage.setting.put(DanmakuKey.danmakuOn, next);
    if (!next) {
      try {
        _danmakuController?.clear();
      } catch (_) {}
    }
  }

  void togglePlatformVisibility(String platform) {
    final next = Set<String>.from(state.hiddenPlatforms);
    if (next.contains(platform)) {
      next.remove(platform);
    } else {
      next.add(platform);
    }
    state = state.copyWith(hiddenPlatforms: next);
    try {
      _danmakuController?.clear();
    } catch (_) {}
  }

  bool isPlatformHidden(String platform) {
    return state.hiddenPlatforms.contains(platform);
  }

  Future<void> setShader(
    int type, {
    required Player player,
    bool synchronized = true,
  }) async {
    final shadersController =
        await ref.read(shadersControllerProvider.future);
    final pp = player.platform as NativePlayer;
    await pp.waitForPlayerInitialization;
    await pp.waitForVideoControllerInitializationIfAttached;
    if (type == 2) {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(
          shadersController.shadersDirectory.path,
          Constants.mpvAnime4KShadersLite,
        ),
      ]);
      state = state.copyWith(superResolutionType: 2);
      return;
    }
    if (type == 3) {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(
          shadersController.shadersDirectory.path,
          Constants.mpvAnime4KShaders,
        ),
      ]);
      state = state.copyWith(superResolutionType: 3);
      return;
    }
    await pp.command(['change-list', 'glsl-shaders', 'clr', '']);
    state = state.copyWith(superResolutionType: 1);
  }
}

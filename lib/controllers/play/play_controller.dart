import 'dart:async';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/controllers/shaders/shaders_provider.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:hive_ce/hive.dart';
import 'package:media_kit/media_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:window_manager/window_manager.dart';

part 'play_controller.g.dart';

class PlayState {
  ///播放地址
  final String videoUrl;

  /// 播放地址偏移量
  final int offset;

  /// 超分：0 初始；1 关；2 效率；3 质量
  final int superResolutionType;

  /// 播放页宽屏状态
  final bool isWideScreen;

  /// 播放页内容展开状态
  final bool isContentExpanded;

  /// 全屏状态
  final bool isFullscreen;

  /// 弹幕数据
  final Map<int, List<Danmaku>> danDanmakus;
  final bool danmakuOn;

  /// 隐藏的弹幕平台
  final Set<String> hiddenPlatforms;

  const PlayState({
    this.superResolutionType = 0,
    this.isWideScreen = false,
    this.isContentExpanded = true,
    this.isFullscreen = false,
    this.danDanmakus = const <int, List<Danmaku>>{},
    this.danmakuOn = true,
    this.hiddenPlatforms = const <String>{},
    this.videoUrl = '',
    this.offset = 0,
  });

  PlayState copyWith({
    String? videoUrl,
    int? offset,
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
      videoUrl: videoUrl ?? this.videoUrl,
      offset: offset ?? this.offset,
    );
  }
}

/// 播放初始化参数
class PlayInitParams {
  final String videoRrl;
  final int offset;

  const PlayInitParams({
    required this.videoRrl,
    required this.offset,
  });
}

Set<String> _hiddenPlatformsFromStorage() {
  final Box setting = Storage.setting;
  final platformBilibili = setting.get(DanmakuKey.danmakuPlatformBilibili,
      defaultValue: true) as bool;
  final platformGamer =
      setting.get(DanmakuKey.danmakuPlatformGamer, defaultValue: true) as bool;
  final platformDanDanPlay = setting.get(DanmakuKey.danmakuPlatformDanDanPlay,
      defaultValue: true) as bool;

  const platformNameBilibili = 'BiliBili';
  const platformNameGamer = 'Gamer';
  const platformNameDanDanPlay = '弹弹Play';

  final hidden = <String>{};
  if (!platformBilibili) hidden.add(platformNameBilibili);
  if (!platformGamer) hidden.add(platformNameGamer);
  if (!platformDanDanPlay) hidden.add(platformNameDanDanPlay);
  return hidden;
}

/// 使用方式：`ref.watch(playProvider)` / `ref.read(playProvider.notifier)`。
/// [DanmakuController] 由弹幕组件创建后调用 [attachDanmakuController]。
@riverpod
class PlayController extends _$PlayController {
  DanmakuController? _danmakuController;
  Timer? _saveSettingsTimer;

  DanmakuController? readDanmakuController() => _danmakuController;

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

  ///初始化播放资源
  /// TODO 以后需要将剧集名称、番剧名称、剧集号在这初始化
  Future<void> init(PlayInitParams params) async {
    state = state.copyWith(videoUrl: params.videoRrl, offset: params.offset);
  }

  /// 换集或停止时清空，避免 [VideoView] 仍按旧 URL 认为可播。
  void clearPlaybackSource() {
    state = state.copyWith(videoUrl: '', offset: 0);
  }

  /// 从存储同步平台显示/隐藏
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

  /// 切换内容区域展开状态
  void toggleContentExpanded() {
    state = state.copyWith(isContentExpanded: !state.isContentExpanded);
  }

  /// 进入全屏
  void enterFullScreen() {
    state = state.copyWith(isFullscreen: true);
    SystemUtil.enterFullScreen();
  }

  /// 退出全屏
  void exitFullScreen() {
    state = state.copyWith(isFullscreen: false);
    SystemUtil.exitFullScreen();
  }

  /// 切换全屏状态
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
    final shadersController = await ref.read(shadersControllerProvider.future);
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

// 兼容旧调用点：ref.watch(playController) / ref.read(playController.notifier)
final playController = playControllerProvider;

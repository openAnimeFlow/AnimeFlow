import 'dart:async';
import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/controllers/shaders/shaders_controller.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

class PlayController extends GetxController {
  /// 视频超分
  /// 1. 关闭
  /// 2. 效率档
  /// 3. 质量档
  final superResolutionType = 0.obs;

  /// 宽屏状态
  final isWideScreen = false.obs;

  /// 内容区域展开状态
  final isContentExpanded = true.obs;

  /// 全屏状态
  final isFullscreen = false.obs;

  ///弹幕相关
  final RxMap<int, List<Danmaku>> danDanmakus = <int, List<Danmaku>>{}.obs;
  late DanmakuController danmakuController;
  final RxBool danmakuOn = true.obs;
  final RxSet<String> hiddenPlatforms = <String>{}.obs;
  Timer? _saveSettingsTimer;

  ///着色器
  late ShadersController shadersController;

  @override
  void onInit() {
    super.onInit();
    _initPlatformVisibility();
    shadersController = Get.find<ShadersController>();
  }

  /// 初始化平台显示/隐藏状态（从持久化设置读取）
  void _initPlatformVisibility() {
    syncPlatformVisibilityFromStorage();
  }

  /// 从存储同步平台显示/隐藏状态
  void syncPlatformVisibilityFromStorage() {
    final Box setting = Storage.setting;

    // 读取各平台的显示设置
    final platformBilibili =
        setting.get(DanmakuKey.danmakuPlatformBilibili, defaultValue: true);
    final platformGamer =
        setting.get(DanmakuKey.danmakuPlatformGamer, defaultValue: true);
    final platformDanDanPlay =
        setting.get(DanmakuKey.danmakuPlatformDanDanPlay, defaultValue: true);

    // 平台名称映射（从 source 字段中提取的实际名称，如 [BiliBili]、[Gamer]）
    const String platformNameBilibili = 'BiliBili';
    const String platformNameGamer = 'Gamer';
    const String platformNameDanDanPlay = '弹弹Play';

    // 根据设置更新 hiddenPlatforms
    if (!platformBilibili) {
      if (!hiddenPlatforms.contains(platformNameBilibili)) {
        hiddenPlatforms.add(platformNameBilibili);
      }
    } else {
      hiddenPlatforms.remove(platformNameBilibili);
    }

    if (!platformGamer) {
      if (!hiddenPlatforms.contains(platformNameGamer)) {
        hiddenPlatforms.add(platformNameGamer);
      }
    } else {
      hiddenPlatforms.remove(platformNameGamer);
    }

    if (!platformDanDanPlay) {
      if (!hiddenPlatforms.contains(platformNameDanDanPlay)) {
        hiddenPlatforms.add(platformNameDanDanPlay);
      }
    } else {
      hiddenPlatforms.remove(platformNameDanDanPlay);
    }

    // 同步后清空屏幕弹幕，让新设置生效
    try {
      danmakuController.clear();
    } catch (_) {}
  }

  void updateIsWideScreen(bool value) {
    if (isWideScreen.value != value) {
      isWideScreen.value = value;
    }
  }

  // 切换内容区域展开状态
  void toggleContentExpanded() {
    isContentExpanded.value = !isContentExpanded.value;
  }

  /// 进入全屏
  void enterFullScreen() {
    isFullscreen.value = true;
    // 移动端全屏时自动横屏
    Utils.enterFullScreen();
  }

  /// 退出全屏
  void exitFullScreen() {
    isFullscreen.value = false;
    Utils.exitFullScreen();
  }

  /// 切换全屏状态
  void toggleFullScreen() {
    if (isFullscreen.value) {
      exitFullScreen();
    } else {
      enterFullScreen();
    }
  }

  /// 检测桌面端全屏状态
  ///
  Future<void> checkDesktopFullscreen() async {
    if (Utils.isDesktop) {
      isFullscreen.value = await windowManager.isFullScreen();
    }
  }

  /// 处理全屏变化
  /// 在全屏切换时清空弹幕
  void handleFullscreenChange() {
    try {
      danmakuController.clear();
    } catch (_) {
      // 如果控制器未初始化，忽略错误
    }
  }

  void addDanmaku(List<Danmaku> danmaku) {
    // 按时间分组
    danDanmakus.clear();
    for (var item in danmaku) {
      int second = item.time.toInt();
      if (!danDanmakus.containsKey(second)) {
        danDanmakus[second] = [];
      }
      danDanmakus[second]!.add(item);
    }
  }

  void removeDanmaku() {
    danmakuController.clear();
    danDanmakus.clear();
  }

  /// 切换弹幕开关
  void toggleDanmaku() {
    danmakuOn.value = !danmakuOn.value;
    Storage.setting.put(DanmakuKey.danmakuOn, danmakuOn.value);
    if (!danmakuOn.value) {
      try {
        danmakuController.clear();
      } catch (_) {}
    }
  }

  /// 切换平台显示/隐藏状态
  void togglePlatformVisibility(String platform) {
    if (hiddenPlatforms.contains(platform)) {
      hiddenPlatforms.remove(platform);
    } else {
      hiddenPlatforms.add(platform);
    }
    // 清空屏幕上的弹幕，新弹幕会按照新的隐藏状态过滤
    try {
      danmakuController.clear();
    } catch (_) {}
  }

  /// 检查平台是否被隐藏
  bool isPlatformHidden(String platform) {
    return hiddenPlatforms.contains(platform);
  }

  ///设置超分辨率
  /// type 1 关闭 2 效率档 3 质量档
  Future<void> setShader(int type,
      {required Player player, bool synchronized = true}) async {
    var pp = player.platform as NativePlayer;
    await pp.waitForPlayerInitialization;
    await pp.waitForVideoControllerInitializationIfAttached;
    if (type == 2) {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(shadersController.shadersDirectory.path,
            Constants.mpvAnime4KShadersLite),
      ]);
      superResolutionType.value = 2;
      return;
    }
    if (type == 3) {
      await pp.command([
        'change-list',
        'glsl-shaders',
        'set',
        Utils.buildShadersAbsolutePath(shadersController.shadersDirectory.path,
            Constants.mpvAnime4KShaders),
      ]);
      superResolutionType.value = 3;
      return;
    }
    await pp.command(['change-list', 'glsl-shaders', 'clr', '']);
    superResolutionType.value = 1;
  }

  @override
  void onClose() {
    _saveSettingsTimer?.cancel();
    super.onClose();
  }
}

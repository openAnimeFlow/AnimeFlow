import 'dart:async';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/utils/storage.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class PlayController extends GetxController {
  final isWideScreen = false.obs; // 宽屏状态
  final isContentExpanded = true.obs; // 内容区域展开状态
  final isFullscreen = false.obs; // 全屏状态

  ///弹幕相关
  final RxMap<int, List<Danmaku>> danDanmakus = <int, List<Danmaku>>{}.obs;
  late DanmakuController danmakuController;
  final RxBool danmakuOn = true.obs;
  Timer? _saveSettingsTimer;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _saveSettingsTimer?.cancel();
    super.onClose();
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
    // 移动端全屏时自动横屏，桌面端不需要
    Utils.enterFullScreen(lockOrientation: Utils.isMobile);
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
}

class DanmakuKey {
  static const String danmakuOn = 'danmaku_on',
      danmakuFontSize = 'danmaku_font_size',
      danmakuArea = 'danmaku_area',
      danmakuOpacity = 'danmaku_opacity',
      danmakuHideScroll = 'danmaku_hide_scroll',
      danmakuHideTop = 'danmaku_hide_top',
      danmakuHideBottom = 'danmaku_hide_bottom',
      danmakuDuration = 'danmaku_duration',
      danmakuMassiveMode = 'danmaku_massive_mode',
      danmakuBorder = 'danmaku_border',
      danmakuColor = 'danmaku_color',
      danmakuLineHeight = 'danmaku_line_height',
      danmakuFontWeight = 'danmaku_font_weight',
      danmakuUseSystemFont = 'danmaku_use_system_font';
}

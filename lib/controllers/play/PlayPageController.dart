import 'dart:async';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
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
    loadDanmakuSettings();
  }

  @override
  void onClose() {
    _saveSettingsTimer?.cancel();
    _saveDanmakuSettingsImmediately();
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
    _saveDanmakuOn();
    if (!danmakuOn.value) {
      try {
        danmakuController.clear();
      } catch (_) {
      }
    }
  }

  // 弹幕设置持久化键名
  static const String _danmakuOnKey = 'danmaku_on';
  static const String _danmakuFontSizeKey = 'danmaku_font_size';
  static const String _danmakuAreaKey = 'danmaku_area';
  static const String _danmakuOpacityKey = 'danmaku_opacity';
  static const String _danmakuHideScrollKey = 'danmaku_hide_scroll';
  static const String _danmakuHideTopKey = 'danmaku_hide_top';
  static const String _danmakuHideBottomKey = 'danmaku_hide_bottom';
  static const String _danmakuDurationKey = 'danmaku_duration';
  static const String _danmakuMassiveModeKey = 'danmaku_massive_mode';
  static const String _danmakuBorderKey = 'danmaku_border';
  static const String _danmakuColorKey = 'danmaku_color';

  /// 加载弹幕设置
  Future<void> loadDanmakuSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载弹幕开关
    danmakuOn.value = prefs.getBool(_danmakuOnKey) ?? true;
  }

  /// 保存弹幕开关
  Future<void> _saveDanmakuOn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_danmakuOnKey, danmakuOn.value);
  }

  /// 保存弹幕配置
  void saveDanmakuSettings() {
    _saveSettingsTimer?.cancel();
    // 设置新的定时器，500ms后执行保存
    _saveSettingsTimer = Timer(const Duration(milliseconds: 500), () {
      _saveDanmakuSettingsImmediately();
    });
  }

  /// 立即保存弹幕配置
  Future<void> _saveDanmakuSettingsImmediately() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final option = danmakuController.option;

      await prefs.setDouble(_danmakuFontSizeKey, option.fontSize);
      await prefs.setDouble(_danmakuAreaKey, option.area);
      await prefs.setDouble(_danmakuOpacityKey, option.opacity);
      await prefs.setBool(_danmakuHideScrollKey, option.hideScroll);
      await prefs.setBool(_danmakuHideTopKey, option.hideTop);
      await prefs.setBool(_danmakuHideBottomKey, option.hideBottom);
      await prefs.setDouble(_danmakuDurationKey, option.duration);
      await prefs.setBool(_danmakuMassiveModeKey, option.massiveMode);
    } catch (_) {
    }
  }

  /// 获取保存的弹幕配置
  Future<Map<String, dynamic>> getSavedDanmakuSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fontSize': prefs.getDouble(_danmakuFontSizeKey),
      'area': prefs.getDouble(_danmakuAreaKey),
      'opacity': prefs.getDouble(_danmakuOpacityKey),
      'hideScroll': prefs.getBool(_danmakuHideScrollKey),
      'hideTop': prefs.getBool(_danmakuHideTopKey),
      'hideBottom': prefs.getBool(_danmakuHideBottomKey),
      'duration': prefs.getDouble(_danmakuDurationKey),
      'massiveMode': prefs.getBool(_danmakuMassiveModeKey),
      'border': prefs.getBool(_danmakuBorderKey),
      'danmakuColor': prefs.getBool(_danmakuColorKey),
    };
  }

  /// 保存边框设置
  Future<void> saveDanmakuBorder(bool border) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_danmakuBorderKey, border);
  }

  /// 保存颜色设置
  Future<void> saveDanmakuColor(bool danmakuColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_danmakuColorKey, danmakuColor);
  }
}

import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class PlayController extends GetxController {
  final isWideScreen = false.obs; // 宽屏状态
  final isContentExpanded = true.obs; // 内容区域展开状态
  final isFullscreen = false.obs; // 全屏状态

  ///弹幕相关
  final RxMap<int, List<Danmaku>> danDanmakus = <int, List<Danmaku>>{}.obs;
  late DanmakuController danmakuController;
  final RxBool danmakuOn = true.obs; // 弹幕开关状态
  final RxDouble danmakuFontSize = 20.0.obs;
  final RxDouble danmakuArea = 1.0.obs; // 弹幕显示区域，默认100%
  final RxBool danmakuScroll = true.obs;
  final RxBool danmakuHideTop = true.obs;
  final RxBool danmakuHideBottom = true.obs;

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
    danDanmakus.clear();
  }

  /// 切换弹幕开关
  void toggleDanmaku() {
    danmakuOn.value = !danmakuOn.value;
    if (!danmakuOn.value) {
      try {
        danmakuController.clear();
      } catch (_) {
      }
    }
  }

  ///设置弹幕字体大小
  void setDanmakuFontSize(double fontSize) {
    danmakuFontSize.value = fontSize;
    try {
      danmakuController.updateOption(
        danmakuController.option.copyWith(fontSize: fontSize),
      );
    } catch (_) {
    }
  }

  ///弹幕显示区域
  void setDanmakuArea(double area) {
    danmakuArea.value = area;
    try {
      danmakuController.updateOption(
        danmakuController.option.copyWith(area: area),
      );
    } catch (_) {
    }
  }

  ///滚动弹幕
  void setScrollDanmaku(bool scroll){
    danmakuScroll.value = scroll;
    try {
      danmakuController.updateOption(
        danmakuController.option.copyWith(hideScroll: scroll),
      );
    } catch (_) {
    }
  }

  ///顶部弹幕
  void setTopDanmaku(bool top){
    danmakuHideTop.value = top;
    try {
      danmakuController.updateOption(
        danmakuController.option.copyWith(hideTop: top),
      );
    } catch (_) {
    }
  }

  ///底部弹幕
  void setBottomDanmaku(bool bottom){
    danmakuHideBottom.value = bottom;
    try {
      danmakuController.updateOption(
        danmakuController.option.copyWith(hideBottom: bottom),
      );
    } catch (_) {
    }
  }
}

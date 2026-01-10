import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:canvas_danmaku/danmaku_controller.dart';
import 'package:get/get.dart';

class PlayController extends GetxController {
  RxList<Danmaku> danmaku = <Danmaku>[].obs;
  // 按时间（秒）分组的弹幕数据，用于 canvas_danmaku 显示
  final RxMap<int, List<Danmaku>> danDanmakus = <int, List<Danmaku>>{}.obs;
  late DanmakuController danmakuController;
  final isWideScreen = false.obs; // 宽屏状态
  final isContentExpanded = true.obs;// 内容区域展开状态

  void updateIsWideScreen(bool value) {
    isWideScreen.value = value;
  }

  // 切换内容区域展开状态
  void toggleContentExpanded() {
    isContentExpanded.value = !isContentExpanded.value;
  }

  void addDanmaku(List<Danmaku> danmaku) {
    this.danmaku.addAll(danmaku);
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
    danmaku.clear();
    danDanmakus.clear();
  }
}

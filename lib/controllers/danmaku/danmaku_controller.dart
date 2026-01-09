import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:get/get.dart';

class DanmakuController extends GetxController  {
  RxList<Danmaku> danmaku = <Danmaku>[].obs;
  
  // 按时间（秒）分组的弹幕数据，用于 canvas_danmaku 显示
  Map<int, List<Danmaku>> danDanmakus = {};
  
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

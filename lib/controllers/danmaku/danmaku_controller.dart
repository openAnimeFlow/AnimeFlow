import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:get/get.dart';

class DanmakuController extends GetxController {
  RxList<Danmaku> danmaku = <Danmaku>[].obs;

  void addDanmaku(List<Danmaku> danmaku) {
    this.danmaku.addAll(danmaku);
  }

  void removeDanmaku() {
    danmaku.close();
  }
}

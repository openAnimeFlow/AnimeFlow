import 'package:get/get.dart';

class PlayPageController extends GetxController {
  final isWideScreen = false.obs; // 宽屏状态
  final isContentExpanded = true.obs;// 内容区域展开状态

  void updateIsWideScreen(bool value) {
    isWideScreen.value = value;
  }

  // 切换内容区域展开状态
  void toggleContentExpanded() {
    isContentExpanded.value = !isContentExpanded.value;
  }
}

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class SettingController extends GetxController {
  final isWideScreen = false.obs;

  void setWideScreen(bool value) {
    isWideScreen.value = value;
  }
}

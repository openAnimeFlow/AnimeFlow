import 'package:get/get.dart';

class MainPageState extends GetxController {
  final isDesktop = false.obs;

  void changeIsDesktop(bool value) {
    isDesktop.value = value;
  }
}

import 'package:anime_flow/controllers/my_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_view/login_view.dart';
import 'no_login/no_login_view.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  bool isPinned = false;
  late final MyController myController;

  @override
  void initState() {
    super.initState();
    myController = Get.find<MyController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => myController.userInfo.value == null
          ? const Scaffold(body: NoLoginView())
          : Scaffold(
              body: LoginView(
                userInfoItem: myController.userInfo.value!,
              ),
            ),
    );
  }
}

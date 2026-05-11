import 'package:anime_flow/stores/user_info_store.dart';
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
  late final UserInfoStore userInfoStore;

  @override
  void initState() {
    super.initState();
    userInfoStore = Get.find<UserInfoStore>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => userInfoStore.userInfo.value == null
          ? const Scaffold(body: NoLoginView())
          : Scaffold(
              body: LoginView(
                userInfoItem: userInfoStore.userInfo.value!,
              ),
            ),
    );
  }
}

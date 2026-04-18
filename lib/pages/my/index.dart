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
  late UserInfoStore userInfoStore;

  @override
  void initState() {
    super.initState();
    userInfoStore = Get.find<UserInfoStore>();
    _initialize();
  }

  void _initialize() async {
    // _appLinks = AppLinks();
    // _listenForDeepLink(_appLinks);
  }

  /// 冷启动 OAuth 回调由 [GoRouter.redirect] 处理；此处监听应用在**已运行**时
  // Future<void> _listenForDeepLink(AppLinks appLinks) async {
  //   try {
  //     appLinks.uriLinkStream.listen((Uri uri) async {
  //       await MyController.handleDeepLink(uri.toString());
  //     });
  //   } catch (e) {
  //     Logger().e("Error in deep link listener: $e");
  //   }
  // }

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

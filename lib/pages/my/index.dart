import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/stores/TokenStorage.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import 'login_view.dart';
import 'my_controller.dart';
import 'no_login_view.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  late AppLinks _appLinks;
  bool isPinned = false;
  late UserInfoStore userInfoStore;

  @override
  void initState() {
    super.initState();
    userInfoStore = Get.find<UserInfoStore>();
    _initialize();
  }

  void _initialize() async {
    _appLinks = AppLinks();
    _listenForDeepLink(_appLinks);
  }

  Future<void> _listenForDeepLink(AppLinks appLinks) async {
    try {
      final initialLink = await appLinks.getInitialLink();
      // if (initialLink != null) {
      //   await MyController.handleDeepLink(initialLink.toString());
      //   _getUserInfo();
      // }

      // 监听深度链接
      appLinks.uriLinkStream.listen((Uri uri) async {
        await MyController.handleDeepLink(uri.toString());
        _getUserInfo();
      });
    } catch (e) {
      Logger().e("Error in deep link listener: $e");
    }
  }

  Future<void> _getUserInfo() async {
    // 如果已有正在进行的请求，不重复请求
    final token = await tokenStorage.getToken();
    if (token != null) {
      _fetchUserInfo(token.userId);
    }
  }

  Future<void> _fetchUserInfo(int userId) async {
    try {
      final token = await tokenStorage.getToken();
      if(token != null) {
        final userInfo =
        await UserRequest.queryUserInfoService(userId.toString());
        if (mounted) {
          userInfoStore.userInfo.value = userInfo;
        }
      }
    } catch (e) {
      Logger().e("Error fetching user info: $e");
    }
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

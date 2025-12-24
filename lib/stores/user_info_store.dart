import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:get/get.dart';

import 'TokenStorage.dart';

class UserInfoStore extends GetxController {
  Rx<UserInfoItem?> userInfo = Rx<UserInfoItem?>(null);

  ///初始化
  void _init() async {
    final token = await tokenStorage.getToken();
    if (token != null) {
      userInfo.value =
          await UserRequest.queryUserInfoService(token.userId.toString());
    }
  }

  ///清理userInfo
  void clearUserInfo() {
    userInfo.value = null;
    tokenStorage.deleteToken();
  }

  @override
  void onInit() {
    super.onInit();
    _init();
  }
}

import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:get/get.dart';

class UserSpaceStores extends GetxController {
  final Rx<UserInfoItem> userInfo;

  /// 函数构造方法
  UserSpaceStores(UserInfoItem userInfo) : userInfo = Rx(userInfo);
}

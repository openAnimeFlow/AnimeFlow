import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  /// 获取当前登录用户的完整资料（/me → 详情）
  Future<UserInfoItem> getCurrentUserProfile() async {
    final me = await UserRequest.userInfoService();
    return UserRequest.queryUserInfoService(me.username);
  }

  /// 按用户名查询用户资料
  Future<UserInfoItem> getUserProfile(String username) {
    return UserRequest.queryUserInfoService(username);
  }
}

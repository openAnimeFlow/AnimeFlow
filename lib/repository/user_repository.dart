import 'package:anime_flow/crawler/itme/bgm_user_page_item.dart';
import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/models/item/flow/flow_token.dart';
import 'package:anime_flow/models/item/flow/flow_users.dart';

class UserRepository {
  UserRepository._();

  static final UserRepository instance = UserRepository._();

  /// 获取当前登录的 AnimeFlow 用户资料。
  Future<FlowUsers> getCurrentUserProfile(FlowToken flowToken) {
    return FlowRequest.getUserInfoService(
      token: flowToken.accessToken,
      tokenType: flowToken.tokenType,
    );
  }

  /// 按用户名查询 Bangumi 用户资料
  Future<UserInfoItem> getUserProfile(String username) {
    return FlowRequest.queryUserInfoService(username);
  }

  /// 获取用户统计信息
  Future<BgmUserStatisticsItem> getUserStatistics(String username) async {
    return await FlowRequest.getBgmUserStatisticsService(username);
  }
}

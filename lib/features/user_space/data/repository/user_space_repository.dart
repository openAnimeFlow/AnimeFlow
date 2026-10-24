import 'package:anime_flow/core/crawler/item/bgm_user_statistics_item.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/bangumi/user_info_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userSpaceRepositoryProvider = Provider<UserSpaceRepository>(
  (ref) => const UserSpaceRepository(),
);

/// Bangumi 公开用户空间的数据访问。
class UserSpaceRepository {
  const UserSpaceRepository();

  Future<UserInfoItem> getUserProfile(String username) {
    return FlowApi.queryUserInfoService(username);
  }

  Future<BgmUserStatisticsItem> getUserStatistics(String username) {
    return FlowApi.getBgmUserStatisticsService(username);
  }
}

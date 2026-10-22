import 'package:anime_flow/core/crawler/item/bgm_user_statistics_item.dart';
import 'package:anime_flow/shared/models/bangumi/user_info_item.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_space_provider.g.dart';

@riverpod
class UserSpace extends _$UserSpace {
  @override
  Future<UserInfoItem> build(String username) async {
    return FlowApi.queryUserInfoService(username);
  }
}

@riverpod
class UserSpaceStatistics extends _$UserSpaceStatistics {
  @override
  Future<BgmUserStatisticsItem> build(String username) async {
    return FlowApi.getBgmUserStatisticsService(username);
  }
}

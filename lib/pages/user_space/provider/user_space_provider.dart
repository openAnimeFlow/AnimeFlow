import 'package:anime_flow/crawler/itme/bgm_user_page_item.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/repository/providers/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_space_provider.g.dart';

@riverpod
class UserSpace extends _$UserSpace {
  @override
  Future<UserInfoItem> build(String username) async {
    return ref.read(userRepositoryProvider).getUserProfile(username);
  }
}

@riverpod
class UserSpaceStatistics extends _$UserSpaceStatistics {
  @override
  Future<BgmUserStatisticsItem> build(String username) async {
    return ref.read(userRepositoryProvider).getUserStatistics(username);
  }
}

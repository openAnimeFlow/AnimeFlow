import 'dart:typed_data';

import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => const UserRepository(),
);

/// 当前登录的 AnimeFlow 账号资料。
class UserRepository {
  const UserRepository();

  /// 获取当前登录的 AnimeFlow 用户资料。
  Future<FlowUsers> getCurrentUserProfile(FlowToken flowToken) {
    return FlowApi.getUserInfoService(
      token: flowToken.accessToken,
      tokenType: flowToken.tokenType,
    );
  }

  Future<FlowUsers> uploadAvatar(Uint8List imageBytes) {
    return FlowApi.uploadAvatarService(imageBytes);
  }

  Future<FlowUsers> updateNickname(String nickname) {
    return FlowApi.updateUserInfoService(nickname: nickname);
  }

  Future<FlowUsers> updateBackground(int? backgroundId) {
    return FlowApi.updateUserInfoService(backgroundId: backgroundId);
  }
}

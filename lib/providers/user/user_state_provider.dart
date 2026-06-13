import 'package:anime_flow/http/interceptors/bgm_refresh_token_interceptor.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/repository/providers/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_state_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrentUserToken extends _$CurrentUserToken {
  @override
  Future<TokenItem?> build() async {
    BgmRefreshTokenInterceptor.onSessionExpired = () {
      ref.invalidateSelf();
      ref.invalidate(currentUserInfoProvider);
    };
    return ref.watch(tokenRepositoryProvider).getToken();
  }
}

@Riverpod(keepAlive: true)
Future<bool> isLoggedIn(Ref ref) async {
  final token = await ref.watch(currentUserTokenProvider.future);
  return token != null;
}

@Riverpod(keepAlive: true)
class CurrentUserInfo extends _$CurrentUserInfo {
  @override
  Future<UserInfoItem?> build() async {
    final userRepository = ref.watch(userRepositoryProvider);
    final token = await ref.watch(currentUserTokenProvider.future);
    if (token == null) {
      return null;
    }

    try {
      return await userRepository.getCurrentUserProfile();
    } catch (error, stackTrace) {
      final latestToken = await ref.read(tokenRepositoryProvider).getToken();
      if (latestToken == null) {
        return null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

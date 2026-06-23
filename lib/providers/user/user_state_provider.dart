import 'package:anime_flow/http/interceptors/bgm_refresh_token_interceptor.dart';
import 'package:anime_flow/http/interceptors/flow_refresh_token_interceptor.dart';
import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/flow/bangumi_bind_item.dart';
import 'package:anime_flow/models/item/flow/flow_token.dart';
import 'package:anime_flow/models/item/flow/flow_users.dart';
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
class CurrentFlowToken extends _$CurrentFlowToken {
  @override
  Future<FlowToken?> build() async {
    FlowRefreshTokenInterceptor.onSessionExpired = () {
      ref.invalidateSelf();
      ref.invalidate(isLoggedInProvider);
      ref.invalidate(currentUserInfoProvider);
      ref.invalidate(bangumiBindProvider);
    };
    FlowRefreshTokenInterceptor.onTokenRefreshed = () {
      ref.invalidateSelf();
    };
    return ref.watch(flowTokenRepositoryProvider).getToken();
  }
}

@Riverpod(keepAlive: true)
Future<bool> isLoggedIn(Ref ref) async {
  final token = await ref.watch(currentFlowTokenProvider.future);
  return token != null;
}

@Riverpod(keepAlive: true)
Future<BangumiBindItem?> bangumiBind(Ref ref) async {
  final isLoggedIn = await ref.watch(isLoggedInProvider.future);
  if (!isLoggedIn) {
    return null;
  }

  try {
    return await FlowRequest.getBangumiBindService();
  } catch (error, stackTrace) {
    final latestToken = await ref.read(flowTokenRepositoryProvider).getToken();
    if (latestToken == null) {
      return null;
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
}

@Riverpod(keepAlive: true)
class CurrentUserInfo extends _$CurrentUserInfo {
  @override
  Future<FlowUsers?> build() async {
    final userRepository = ref.watch(userRepositoryProvider);
    final flowToken = await ref.watch(currentFlowTokenProvider.future);
    if (flowToken == null) {
      return null;
    }

    try {
      return await userRepository.getCurrentUserProfile(flowToken);
    } catch (error, stackTrace) {
      final latestToken = await ref.read(flowTokenRepositoryProvider).getToken();
      if (latestToken == null) {
        return null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

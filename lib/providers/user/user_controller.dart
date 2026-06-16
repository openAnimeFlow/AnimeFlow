import 'dart:io';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/clients/anime_flow_client.dart';
import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/flow/bangumi_bind_item.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/providers/user/user_oauth_state.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/repository/providers/repository_providers.dart';
import 'package:anime_flow/repository/token_repository.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'user_controller.g.dart';

@Riverpod(keepAlive: true)
class UserController extends _$UserController {
  @override
  UserOAuthState build() => const UserOAuthState();

  TokenRepository get _tokenRepository => ref.read(tokenRepositoryProvider);

  void cancelOAuthWaiting() {
    state = const UserOAuthState();
  }

  Future<TokenItem?> getToken() => _tokenRepository.getToken();

  Future<void> clearUserInfo() async {
    await _tokenRepository.removeToken();
    await ref.read(flowTokenRepositoryProvider).removeToken();
    ref.invalidate(currentUserTokenProvider);
    ref.invalidate(currentFlowTokenProvider);
    ref.invalidate(currentUserInfoProvider);
    ref.invalidate(bangumiBindProvider);
  }

  Future<void> handleDeepLink(String deepLink) async {
    final purpose = state.purpose ?? OAuthPurpose.login;
    try {
      final uri = Uri.parse(deepLink);
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        cancelOAuthWaiting();
        return;
      }

      if (purpose == OAuthPurpose.bindBangumi) {
        await _completeBangumiBind(code);
      } else {
        final token = await FlowRequest.getTokenService(code: code);
        await _tokenRepository.saveToken(token);
        ref.invalidate(currentUserTokenProvider);
        ref.invalidate(currentUserInfoProvider);
      }
    } catch (e) {
      final message = e is AnimeFlowApiException
          ? e.message
          : purpose == OAuthPurpose.bindBangumi
              ? 'Bangumi 绑定失败'
              : '登录后拉取用户信息失败';
      LiggLogger().e('$message: $e');
      NotificationToast.show('提示', message);
    } finally {
      cancelOAuthWaiting();
    }
  }

  Future<void> openOAuthPage() {
    return _openOAuth(
      purpose: OAuthPurpose.login,
      bindMode: false,
    );
  }

  Future<void> openOAuthPageForBind() async {
    final isLoggedIn = await ref.read(isLoggedInProvider.future);
    if (!isLoggedIn) {
      throw StateError('请先登录 AnimeFlow 账号');
    }
    return _openOAuth(
      purpose: OAuthPurpose.bindBangumi,
      bindMode: true,
    );
  }

  Future<void> _openOAuth({
    required OAuthPurpose purpose,
    required bool bindMode,
  }) async {
    state = UserOAuthState(isAuthorizing: true, purpose: purpose);
    try {
      const clientId = Constants.bgmClientId;
      const redirectUri = AnimeFlowApi.animeFlowApi + AnimeFlowApi.callback;
      final session = await FlowRequest.getSessionService(bindMode: bindMode);
      final sessionId = session['sessionId'] as String;
      final authUrl = Uri.parse(
        '${CommonApi.bgmTV}${BgmApi.oauth}?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&state=$sessionId',
      );
      LiggLogger().d('authUrl: $authUrl');
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(
          authUrl,
          mode: Platform.isIOS
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault,
        );

        if (SystemUtil.isDesktop) {
          if (purpose == OAuthPurpose.bindBangumi) {
            await _pollBindCodeAfterAuth(sessionId);
          } else {
            await _pollTokenAfterAuth(sessionId);
          }
        }
      } else {
        throw 'Could not launch $authUrl';
      }
    } catch (e) {
      cancelOAuthWaiting();
      rethrow;
    }
  }

  Future<BangumiBindItem?> _completeBangumiBind(String code) async {
    final bind = await FlowRequest.bindBangumiService(code: code);
    ref.invalidate(bangumiBindProvider);
    NotificationToast.show('提示', 'Bangumi 账号绑定成功');
    return bind;
  }

  Future<void> _pollTokenAfterAuth(String sessionId) async {
    try {
      LiggLogger().d('开始轮询 token，sessionId: $sessionId');
      final token = await FlowRequest.pollTokenService(state: sessionId);
      if (token != null) {
        await _tokenRepository.saveToken(token);
        ref.invalidate(currentUserTokenProvider);
        ref.invalidate(currentUserInfoProvider);
      } else {
        LiggLogger().w('轮询超时，未获取到 token');
        NotificationToast.show('提示', '授权超时，请重试');
      }
    } catch (e) {
      LiggLogger().e('轮询 token 异常: $e');
      NotificationToast.show('提示', '登录失败，请重试');
    } finally {
      cancelOAuthWaiting();
    }
  }

  Future<void> _pollBindCodeAfterAuth(String sessionId) async {
    try {
      LiggLogger().d('开始轮询绑定授权码，sessionId: $sessionId');
      final code = await FlowRequest.pollBindCodeService(state: sessionId);
      if (code != null && code.isNotEmpty) {
        await _completeBangumiBind(code);
      } else {
        LiggLogger().w('轮询超时，未获取到绑定授权码');
        NotificationToast.show('提示', '绑定授权超时，请重试');
      }
    } catch (e) {
      LiggLogger().e('轮询绑定授权码异常: $e');
      final message =
          e is AnimeFlowApiException ? e.message : 'Bangumi 绑定失败，请重试';
      NotificationToast.show('提示', message);
    } finally {
      cancelOAuthWaiting();
    }
  }
}

/// Bangumi OAuth 应用回调（自定义 scheme）
bool isOAuthAppCallbackUri(Uri uri) {
  return uri.scheme == 'flow' && uri.host == 'auth' && uri.path == '/callback';
}

import 'dart:io';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/repository/providers/repository_providers.dart';
import 'package:anime_flow/repository/token_repository.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'user_controller.g.dart';

@Riverpod(keepAlive: true)
class UserController extends _$UserController {
  @override
  bool build() => false;

  TokenRepository get _tokenRepository => ref.read(tokenRepositoryProvider);

  void cancelOAuthWaiting() {
    state = false;
  }

  Future<TokenItem?> getToken() => _tokenRepository.getToken();

  Future<void> clearUserInfo() async {
    await _tokenRepository.removeToken();
    await ref.read(flowTokenRepositoryProvider).removeToken();
    ref.invalidate(currentUserTokenProvider);
    ref.invalidate(currentFlowTokenProvider);
    ref.invalidate(currentUserInfoProvider);
  }

  Future<void> handleDeepLink(String deepLink) async {
    try {
      final uri = Uri.parse(deepLink);
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        cancelOAuthWaiting();
        return;
      }
      final token = await FlowRequest.getTokenService(code: code);
      await _tokenRepository.saveToken(token);
      ref.invalidate(currentUserTokenProvider);
      ref.invalidate(currentUserInfoProvider);
    } catch (e) {
      LiggLogger().e('登录后拉取用户信息失败: $e');
    } finally {
      cancelOAuthWaiting();
    }
  }

  Future<void> openOAuthPage() async {
    state = true;
    try {
      const clientId = Constants.bgmClientId;
      const redirectUri = AnimeFlowApi.animeFlowApi + AnimeFlowApi.callback;
      final session = await FlowRequest.getSessionService();
      final sessionId = session['sessionId'];
      final authUrl = Uri.parse(
          '${CommonApi.bgmTV}${BgmApi.oauth}?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&state=$sessionId');
      LiggLogger().d('authUrl: $authUrl');
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(
          authUrl,
          mode: Platform.isIOS
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault,
        );

        if (SystemUtil.isDesktop) {
          await _pollTokenAfterAuth(sessionId);
        }
      } else {
        throw 'Could not launch $authUrl';
      }
    } catch (e) {
      cancelOAuthWaiting();
      rethrow;
    }
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
      }
    } catch (e) {
      LiggLogger().e('轮询 token 异常: $e');
    } finally {
      cancelOAuthWaiting();
    }
  }
}

/// Bangumi OAuth 应用回调（自定义 scheme）
bool isOAuthAppCallbackUri(Uri uri) {
  return uri.scheme == 'flow' && uri.host == 'auth' && uri.path == '/callback';
}

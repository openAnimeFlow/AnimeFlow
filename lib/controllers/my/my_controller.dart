import 'dart:io';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/controllers/my/my_state_provider.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/requests/anime_flow_request.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/repository/providers/repository_providers.dart';
import 'package:anime_flow/repository/token_repository.dart';
import 'package:anime_flow/repository/user_repository.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class MyController {
  MyController(this._ref);

  final Ref _ref;

  TokenRepository get _tokenRepository => _ref.read(tokenRepositoryProvider);

  UserRepository get _userRepository => _ref.read(userRepositoryProvider);

  Future<void> init() async {
    final token = await getToken();
    if (token != null) {
      await _refreshCurrentUserProfile();
    }
  }

  void cancelOAuthWaiting() {
    _ref.read(oAuthAuthorizingProvider.notifier).setAuthorizing(false);
  }

  Future<TokenItem?> getToken() => _tokenRepository.getToken();

  Future<void> clearUserInfo() async {
    _ref.read(currentUserInfoProvider.notifier).clear();
    await _tokenRepository.removeToken();
  }

  Future<void> handleDeepLink(String deepLink) async {
    try {
      final uri = Uri.parse(deepLink);
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        cancelOAuthWaiting();
        return;
      }
      final token = await AnimeFlowRequest.getTokenService(code: code);
      await _tokenRepository.saveToken(token);
      await _refreshCurrentUserProfile();
    } catch (e) {
      LiggLogger().e('登录后拉取用户信息失败: $e');
    } finally {
      cancelOAuthWaiting();
    }
  }

  Future<void> openOAuthPage() async {
    _ref.read(oAuthAuthorizingProvider.notifier).setAuthorizing(true);
    try {
      const clientId = Constants.bgmClientId;
      const redirectUri = AnimeFlowApi.animeFlowApi + AnimeFlowApi.callback;
      final session = await AnimeFlowRequest.getSessionService();
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

  Future<void> _refreshCurrentUserProfile() async {
    final profile = await _userRepository.getCurrentUserProfile();
    _ref.read(currentUserInfoProvider.notifier).setUserInfo(profile);
  }

  Future<void> _pollTokenAfterAuth(String sessionId) async {
    try {
      LiggLogger().d('开始轮询 token，sessionId: $sessionId');
      final token = await AnimeFlowRequest.pollTokenService(state: sessionId);
      if (token != null) {
        await _tokenRepository.saveToken(token);
        await _refreshCurrentUserProfile();
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

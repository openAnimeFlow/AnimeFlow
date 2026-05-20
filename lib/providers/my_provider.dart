import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/requests/anime_flow_request.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/repository/BangumiToken.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'my_provider.g.dart';

class MyState {
  const MyState({
    this.userInfo,
    this.isOAuthAuthorizing = false,
  });

  final UserInfoItem? userInfo;
  final bool isOAuthAuthorizing;

  MyState copyWith({
    UserInfoItem? userInfo,
    bool? isOAuthAuthorizing,
    bool clearUserInfo = false,
  }) {
    return MyState(
      userInfo: clearUserInfo ? null : (userInfo ?? this.userInfo),
      isOAuthAuthorizing: isOAuthAuthorizing ?? this.isOAuthAuthorizing,
    );
  }
}

/// Bangumi OAuth 应用回调（自定义 scheme）
bool isOAuthAppCallbackUri(Uri uri) {
  return uri.scheme == 'flow' && uri.host == 'auth' && uri.path == '/callback';
}

@Riverpod(keepAlive: true)
class My extends _$My {
  final BangumiToken _bangumiToken = BangumiToken.instance;

  @override
  MyState build() {
    Future.microtask(_init);
    return const MyState();
  }

  void cancelOAuthWaiting() {
    if (!state.isOAuthAuthorizing) return;
    state = state.copyWith(isOAuthAuthorizing: false);
  }

  Future<TokenItem?> getToken() => _bangumiToken.getToken();

  Future<void> _init() async {
    final token = await getToken();
    if (token == null) return;
    try {
      final me = await UserRequest.userInfoService();
      final info = await UserRequest.queryUserInfoService(me.username);
      state = state.copyWith(userInfo: info);
    } catch (e) {
      LiggLogger().e('初始化用户信息失败: $e');
    }
  }

  void clearUserInfo() {
    state = state.copyWith(clearUserInfo: true);
    _bangumiToken.removeToken();
  }

  Future<void> handleDeepLink(String deepLink) async {
    try {
      final uri = Uri.parse(deepLink);
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        state = state.copyWith(isOAuthAuthorizing: false);
        return;
      }
      final token = await AnimeFlowRequest.getTokenService(code: code);
      await _bangumiToken.saveToken(token);
      final me = await UserRequest.userInfoService();
      final info = await UserRequest.queryUserInfoService(me.username);
      state = state.copyWith(userInfo: info);
    } catch (e) {
      LiggLogger().e('登录后拉取用户信息失败: $e');
    } finally {
      state = state.copyWith(isOAuthAuthorizing: false);
    }
  }

  Future<void> openOAuthPage() async {
    state = state.copyWith(isOAuthAuthorizing: true);
    try {
      const clientId = Constants.bgmClientId;
      const redirectUri = AnimeFlowApi.animeFlowApi + AnimeFlowApi.callback;
      final session = await AnimeFlowRequest.getSessionService();
      final sessionId = session['sessionId'];
      final authUrl = Uri.parse(
        '${CommonApi.bgmTV}${BgmApi.oauth}?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&state=$sessionId',
      );
      LiggLogger().d('authUrl: $authUrl');
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(
          authUrl,
          mode: defaultTargetPlatform == TargetPlatform.iOS
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
      state = state.copyWith(isOAuthAuthorizing: false);
      rethrow;
    }
  }

  Future<void> _pollTokenAfterAuth(String sessionId) async {
    try {
      LiggLogger().d('开始轮询 token，sessionId: $sessionId');
      final token = await AnimeFlowRequest.pollTokenService(state: sessionId);
      if (token != null) {
        await _bangumiToken.saveToken(token);
        final me = await UserRequest.userInfoService();
        final info = await UserRequest.queryUserInfoService(me.username);
        state = state.copyWith(userInfo: info);
      } else {
        LiggLogger().w('轮询超时，未获取到 token');
      }
    } catch (e) {
      LiggLogger().e('轮询 token 异常: $e');
    } finally {
      state = state.copyWith(isOAuthAuthorizing: false);
    }
  }
}

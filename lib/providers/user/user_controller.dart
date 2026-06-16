import 'dart:io';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/clients/flow_client.dart';
import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/flow/bangumi_bind_item.dart';
import 'package:anime_flow/models/item/flow/flow_token.dart';
import 'package:anime_flow/providers/user/bgm_collection_sync_provider.dart';
import 'package:anime_flow/providers/user/user_oauth_state.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/repository/providers/repository_providers.dart';
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

  Future<void> cancelOAuthWaiting() async {
    state = const UserOAuthState();
  }

  Future<void> clearUserInfo() async {
    await ref.read(tokenRepositoryProvider).removeToken();
    await ref.read(flowTokenRepositoryProvider).removeToken();
    ref.invalidate(currentUserTokenProvider);
    ref.invalidate(currentFlowTokenProvider);
    ref.invalidate(isLoggedInProvider);
    ref.invalidate(currentUserInfoProvider);
    ref.invalidate(bangumiBindProvider);
    ref.invalidate(bgmCollectionSyncProvider);
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
        await _completeBangumiLogin(code);
      }
    } catch (e) {
      final message = e is AnimeFlowApiException
          ? e.message
          : purpose == OAuthPurpose.bindBangumi
              ? 'Bangumi 绑定失败'
              : 'Bangumi 授权登录失败';
      LiggLogger().e('$message: $e');
      NotificationToast.show('提示', message);
    } finally {
      cancelOAuthWaiting();
    }
  }

  Future<void> openOAuthPage() {
    return _openOAuth(
      purpose: OAuthPurpose.login,
      storeCode: true,
    );
  }

  Future<void> openOAuthPageForBind() async {
    final isLoggedIn = await ref.read(isLoggedInProvider.future);
    if (!isLoggedIn) {
      throw StateError('请先登录 AnimeFlow 账号');
    }
    return _openOAuth(
      purpose: OAuthPurpose.bindBangumi,
      storeCode: true,
    );
  }

  Future<void> _openOAuth({
    required OAuthPurpose purpose,
    required bool storeCode,
  }) async {
    state = UserOAuthState(isAuthorizing: true, purpose: purpose);
    try {
      const clientId = Constants.bgmClientId;
      const redirectUri = AnimeFlowApi.animeFlowApi + AnimeFlowApi.callback;
      final session =
          await FlowRequest.getSessionService(bindMode: storeCode);
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
          await _pollOAuthCodeAfterAuth(sessionId, purpose);
        }
      } else {
        throw 'Could not launch $authUrl';
      }
    } catch (e) {
      cancelOAuthWaiting();
      rethrow;
    }
  }

  Future<FlowToken> _completeBangumiLogin(String code) async {
    final flowToken = await FlowRequest.bangumiLoginService(
      code: code,
      platform: SystemUtil.getDevice().toUpperCase(),
    );
    await ref.read(flowTokenRepositoryProvider).saveToken(flowToken);
    ref.invalidate(currentFlowTokenProvider);
    ref.invalidate(isLoggedInProvider);
    ref.invalidate(currentUserInfoProvider);
    ref.invalidate(bangumiBindProvider);
    NotificationToast.show('提示', 'Bangumi 授权登录成功');
    return flowToken;
  }

  Future<BangumiBindItem?> _completeBangumiBind(String code) async {
    final bind = await FlowRequest.bindBangumiService(code: code);
    ref.invalidate(bangumiBindProvider);
    ref.invalidate(bgmCollectionSyncProvider);
    NotificationToast.show('提示', 'Bangumi 账号绑定成功');
    return bind;
  }

  Future<void> _pollOAuthCodeAfterAuth(
    String sessionId,
    OAuthPurpose purpose,
  ) async {
    try {
      LiggLogger().d('开始轮询 OAuth 授权码，sessionId: $sessionId');
      final code = await FlowRequest.pollBindCodeService(state: sessionId);
      if (code == null || code.isEmpty) {
        LiggLogger().w('轮询超时，未获取到 OAuth 授权码');
        NotificationToast.show('提示', '授权超时，请重试');
        return;
      }

      if (purpose == OAuthPurpose.bindBangumi) {
        await _completeBangumiBind(code);
      } else {
        await _completeBangumiLogin(code);
      }
    } catch (e) {
      LiggLogger().e('轮询 OAuth 授权码异常: $e');
      final message = e is AnimeFlowApiException
          ? e.message
          : purpose == OAuthPurpose.bindBangumi
              ? 'Bangumi 绑定失败，请重试'
              : 'Bangumi 授权登录失败，请重试';
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

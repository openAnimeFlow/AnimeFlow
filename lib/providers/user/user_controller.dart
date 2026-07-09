import 'dart:io';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/network/api_path.dart';
import 'package:anime_flow/network/clients/flow_client.dart';
import 'package:anime_flow/network/api/flow_request.dart';
import 'package:anime_flow/models/item/flow/bangumi_bind_item.dart';
import 'package:anime_flow/models/item/flow/flow_token.dart';
import 'package:anime_flow/pages/user/provider/user_collection_provider.dart';
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

  void cancelOAuthWaiting() {
    state = const UserOAuthState();
  }

  Future<void> clearUserInfo() async {
    cancelOAuthWaiting();
    await ref.read(tokenRepositoryProvider).removeToken();
    await ref.read(flowTokenRepositoryProvider).removeToken();
    ref.invalidate(currentUserTokenProvider);
    ref.invalidate(currentFlowTokenProvider);
    ref.invalidate(isLoggedInProvider);
    ref.invalidate(currentUserInfoProvider);
    ref.invalidate(bangumiBindProvider);
    ref.invalidate(bgmCollectionSyncProvider);
    ref.invalidate(userCollectionsProvider);
    FlowRequest.logoutService().catchError((e) {
      LiggLogger().w('服务端登出失败: $e');
    });
  }

  Future<OAuthHandleResult> handleDeepLink(String deepLink) async {
    final uri = Uri.parse(deepLink);
    final purpose = _resolveOAuthPurpose(uri);
    try {
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        cancelOAuthWaiting();
        return OAuthHandleResult(
          success: false,
          purpose: purpose,
          errorMessage: '未获取到授权码',
        );
      }

      if (purpose == OAuthPurpose.bindBangumi) {
        await _completeBangumiBind(code);
      } else {
        await _completeBangumiLogin(code);
      }
      return OAuthHandleResult(success: true, purpose: purpose);
    } catch (e, st) {
      final message = _oauthErrorMessage(e, purpose);
      LiggLogger().e(message, error: e, stackTrace: st);
      return OAuthHandleResult(
        success: false,
        purpose: purpose,
        errorMessage: message,
      );
    } finally {
      cancelOAuthWaiting();
    }
  }

  Future<bool> openOAuthPage() {
    return _openOAuth(
      purpose: OAuthPurpose.login,
      storeCode: true,
    );
  }

  Future<bool> openOAuthPageForBind() async {
    final isLoggedIn = await ref.read(isLoggedInProvider.future);
    if (!isLoggedIn) {
      throw StateError('请先登录 AnimeFlow 账号');
    }
    return _openOAuth(
      purpose: OAuthPurpose.bindBangumi,
      storeCode: true,
    );
  }

  Future<bool> _openOAuth({
    required OAuthPurpose purpose,
    required bool storeCode,
  }) async {
    state = UserOAuthState(isAuthorizing: true, purpose: purpose);
    try {
      const clientId = Constants.bgmClientId;
      const redirectUri = AnimeFlowApi.animeFlowApi + AnimeFlowApi.callback;
      final session = await FlowRequest.getSessionService(bindMode: storeCode);
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
          return await _pollOAuthCodeAfterAuth(sessionId, purpose);
        }
        return true;
      }
      throw StateError('无法打开 Bangumi 授权页面');
    } catch (e, st) {
      cancelOAuthWaiting();
      _notifyOAuthError(e, purpose, stackTrace: st);
      return false;
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

  /// 解绑当前账号绑定的 Bangumi 账号。
  Future<BangumiBindItem> unbindBangumi() async {
    final bind = await FlowRequest.unbindBangumiService();
    ref.invalidate(bangumiBindProvider);
    ref.invalidate(bgmCollectionSyncProvider);
    NotificationToast.show('提示', 'Bangumi 账号已解绑');
    return bind;
  }

  Future<bool> _pollOAuthCodeAfterAuth(
    String sessionId,
    OAuthPurpose purpose,
  ) async {
    try {
      LiggLogger().d('开始轮询 OAuth 授权码，sessionId: $sessionId');
      final code = await FlowRequest.pollBindCodeService(state: sessionId);
      if (code == null || code.isEmpty) {
        LiggLogger().w('轮询超时，未获取到 OAuth 授权码');
        NotificationToast.show(
          '提示',
          '授权超时，请重试',
          duration: const Duration(seconds: 10),
        );
        return false;
      }

      if (purpose == OAuthPurpose.bindBangumi) {
        await _completeBangumiBind(code);
      } else {
        await _completeBangumiLogin(code);
      }
      return true;
    } catch (e, st) {
      _notifyOAuthError(e, purpose, stackTrace: st);
      return false;
    } finally {
      cancelOAuthWaiting();
    }
  }

  OAuthPurpose _resolveOAuthPurpose(Uri uri) {
    final current = state.purpose;
    if (current != null) {
      return current;
    }
    if (uri.queryParameters['purpose'] == oauthBindPurposeQueryValue) {
      return OAuthPurpose.bindBangumi;
    }
    return OAuthPurpose.login;
  }

  String _oauthErrorMessage(Object error, OAuthPurpose purpose) {
    return resolveAnimeFlowErrorMessage(
      error,
      fallback: purpose == OAuthPurpose.bindBangumi
          ? 'Bangumi 绑定失败，请重试'
          : 'Bangumi 授权登录失败，请重试',
    );
  }

  void _notifyOAuthError(
    Object error,
    OAuthPurpose purpose, {
    StackTrace? stackTrace,
  }) {
    final message = _oauthErrorMessage(error, purpose);
    LiggLogger().e(message, error: error, stackTrace: stackTrace);
    NotificationToast.show(
      '提示',
      message,
      duration: const Duration(seconds: 10),
    );
  }
}

/// Bangumi OAuth 应用回调（自定义 scheme）
bool isOAuthAppCallbackUri(Uri uri) {
  return uri.scheme == 'flow' && uri.host == 'auth' && uri.path == '/callback';
}

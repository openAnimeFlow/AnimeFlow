import 'dart:io';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/requests/anime_flow_request.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/repository/BangumiToken.dart';
import 'package:anime_flow/repository/user_repository.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class MyController extends GetxController {
  final RxBool isOAuthAuthorizing = false.obs;
  Rx<UserInfoItem?> userInfo = Rx<UserInfoItem?>(null);
  final BangumiToken bangumiToken = BangumiToken.instance;
  final UserRepository userRepository = UserRepository.instance;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  void _setOAuthAuthorizing(bool value) {
    if (isOAuthAuthorizing.value != value) {
      isOAuthAuthorizing.value = value;
    }
  }

  void cancelOAuthWaiting() {
    _setOAuthAuthorizing(false);
  }

  /// 获取Token
  Future<TokenItem?> getToken() async {
    return bangumiToken.getToken();
  }

  ///初始化
  void _init() async {
    final token = await getToken();
    if (token != null) {
      userInfo.value = await userRepository.getCurrentUserProfile();
    }
  }

  ///清理userInfo
  void clearUserInfo() {
    userInfo.value = null;
    bangumiToken.removeToken();
  }

  /// Bangumi OAuth 应用回调（自定义 scheme）
  static bool isOAuthAppCallbackUri(Uri uri) {
    return uri.scheme == 'flow' &&
        uri.host == 'auth' &&
        uri.path == '/callback';
  }

  // 处理深度链接
  Future<void> handleDeepLink(String deepLink) async {
    try {
      final uri = Uri.parse(deepLink);
      final code = uri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        _setOAuthAuthorizing(false);
        return;
      }
      final token = await AnimeFlowRequest.getTokenService(code: code);
      await bangumiToken.saveToken(token);
      userInfo.value = await userRepository.getCurrentUserProfile();
    } catch (e) {
      LiggLogger().e('登录后拉取用户信息失败: $e');
    } finally {
      _setOAuthAuthorizing(false);
    }
  }

  Future<void> openOAuthPage() async {
    _setOAuthAuthorizing(true);
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
          // iOS 必须使用外部 Safari 打开，否则 OAuth 回调无法唤起应用。
          mode: Platform.isIOS
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault,
        );

        // 桌面端：打开授权页面后，启动轮询任务等待用户完成授权
        if (SystemUtil.isDesktop) {
          _pollTokenAfterAuth(sessionId);
        }
      } else {
        throw 'Could not launch $authUrl';
      }
    } catch (e) {
      _setOAuthAuthorizing(false);
      rethrow;
    }
  }

  // 桌面端轮询 token
  Future<void> _pollTokenAfterAuth(String sessionId) async {
    try {
      LiggLogger().d('开始轮询 token，sessionId: $sessionId');
      final token = await AnimeFlowRequest.pollTokenService(state: sessionId);
      if (token != null) {
        await bangumiToken.saveToken(token);
        userInfo.value = await userRepository.getCurrentUserProfile();
      } else {
        LiggLogger().w('轮询超时，未获取到 token');
      }
    } catch (e) {
      LiggLogger().e('轮询 token 异常: $e');
    } finally {
      _setOAuthAuthorizing(false);
    }
  }
}

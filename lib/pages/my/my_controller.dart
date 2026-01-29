import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/http/requests/oauth_request.dart';
import 'package:anime_flow/stores/TokenStorage.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class MyController {
  // 处理深度链接
  static Future<void> handleDeepLink(String deepLink) async {
    final uri = Uri.parse(deepLink);
    String code = uri.queryParameters['code']!;
    if (code.isNotEmpty) {
      Logger().d('获取code:$code');
      // final token = await OAuthRequest.callbackService(code, state);
      final token = await OAuthRequest.getTokenService(code: code);
      Logger().d('获取token:$token');
      await tokenStorage.saveToken(token);
    }
  }

  static void openOAuthPage() async {
    final clientId = dotenv.env['CLIENT_ID'];
    final redirectUri = dotenv.env['REDIRECT_URI'];
    final session = await OAuthRequest.getSessionService();
    final sessionId = session['data']['sessionId'];
    final authUrl = Uri.parse(
        '${BgmApi.baseUrl}${BgmApi.oauth}?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&state=$sessionId');
    Logger().d('authUrl: $authUrl');
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl);

      // 桌面端：打开授权页面后，启动轮询任务等待用户完成授权
      if (SystemUtil.isDesktop) {
        _pollTokenAfterAuth(sessionId);
      }
    } else {
      throw 'Could not launch $authUrl';
    }
  }

  // 桌面端轮询 token
  static Future<void> _pollTokenAfterAuth(String sessionId) async {
    try {
      Logger().d('开始轮询 token，sessionId: $sessionId');
      final token = await OAuthRequest.pollTokenService(state: sessionId);
      if (token != null) {
        Logger().d('轮询获取到 token: $token');
        await tokenStorage.saveToken(token);

        // 获取用户信息并更新 store
        final userInfoStore = Get.find<UserInfoStore>();
        UserRequest.queryUserInfoService(token.userId.toString())
            .then((userInfo) => {userInfoStore.userInfo.value = userInfo});
      } else {
        Logger().w('轮询超时，未获取到 token');
      }
    } catch (e) {
      Logger().e('轮询 token 异常: $e');
    }
  }
}

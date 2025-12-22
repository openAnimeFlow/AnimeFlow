import 'package:anime_flow/http/api/bgm_api.dart';
import 'package:anime_flow/http/requests/oauth_request.dart';
import 'package:anime_flow/stores/TokenStorage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class MyController {
  // 处理深度链接
  static Future<void> handleDeepLink(String deepLink) async {
    final uri = Uri.parse(deepLink);
    String code = uri.queryParameters['code']!;
    String state = uri.queryParameters['state']!;
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
    } else {
      throw 'Could not launch $authUrl';
    }
  }
}

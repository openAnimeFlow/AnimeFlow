import 'package:anime_flow/http/api/bgm_api.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _listenForDeepLink();
  }

  // 监听深度链接
  void _listenForDeepLink() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink.toString());
      }

      // 监听深度链接
      _appLinks.uriLinkStream.listen((Uri uri) {
        _handleDeepLink(uri.toString());
      });
    } catch (e) {
      print("Error in deep link listener: $e");
    }
  }

  // 处理深度链接
  void _handleDeepLink(String deepLink) {
    final uri = Uri.parse(deepLink);
    String code = uri.queryParameters['code'] ?? '';

    if (code.isNotEmpty) {
      Logger().d('获取dode$code');
    }
  }

  void _openOAuthPage() async {
    final clientId = dotenv.env['CLIENT_ID'];
    final redirectUri = dotenv.env['REDIRECT_URI'];
    final authUrl = Uri.parse(
        '${BgmApi.baseUrl}${BgmApi.oauth}?response_type=code&client_id=$clientId&redirect_uri=$redirectUri');
    Logger().d('authUrl: $authUrl');
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl);
    } else {
      throw 'Could not launch $authUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _openOAuthPage();
              },
              child: const Text('登录授权'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:anime_flow/http/api/bgm_api.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import 'my_controller.dart';

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
    _listenForDeepLink(_appLinks);
  }

  void _listenForDeepLink(AppLinks appLinks) async {
    try {
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        MyController.handleDeepLink(initialLink.toString());
      }

      // 监听深度链接
      appLinks.uriLinkStream.listen((Uri uri) {
        MyController.handleDeepLink(uri.toString());
      });
    } catch (e) {
      Logger().e("Error in deep link listener: $e");
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
                MyController.openOAuthPage();
              },
              child: const Text('登录授权'),
            ),
          ],
        ),
      ),
    );
  }
}

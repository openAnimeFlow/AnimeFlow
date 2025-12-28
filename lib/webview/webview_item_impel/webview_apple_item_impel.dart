import 'package:anime_flow/webview/webview_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebviewAppleItemImpel extends StatefulWidget {
  const WebviewAppleItemImpel({super.key});

  @override
  State<WebviewAppleItemImpel> createState() => _WebviewAppleItemImpelState();
}

class _WebviewAppleItemImpelState extends State<WebviewAppleItemImpel> {
  late final WebviewItemController webviewAppleItemController;

  @override
  void initState() {
    super.initState();
    webviewAppleItemController = Get.find<WebviewItemController>();
    webviewAppleItemController.init();
  }

  @override
  void dispose() {
    webviewAppleItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.width * 9.0 / (16.0),
      width: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: const Center(
        child: Text(
          '此平台不支持Webview规则',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

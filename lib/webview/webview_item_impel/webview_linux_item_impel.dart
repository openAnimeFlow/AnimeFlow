import 'package:anime_flow/webview/webview_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebviewLinuxItemImpel extends StatefulWidget {
  const WebviewLinuxItemImpel({super.key});

  @override
  State<WebviewLinuxItemImpel> createState() => _WebviewLinuxItemImpelState();
}

class _WebviewLinuxItemImpelState extends State<WebviewLinuxItemImpel> {
  late final WebviewItemController webviewLinuxItemController;

  @override
  void initState() {
    super.initState();
    webviewLinuxItemController = Get.find<WebviewItemController>();
    webviewLinuxItemController.init();
  }

  @override
  void dispose() {
    webviewLinuxItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.width * 9.0 / (16.0),
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: const Center(child: Text('此平台不支持Webview规则')));
  }
}

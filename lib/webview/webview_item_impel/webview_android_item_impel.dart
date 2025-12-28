import 'package:anime_flow/webview/webview_controller.dart';
import 'package:anime_flow/webview/webview_controller_impel/webview_android_controller_impel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebviewAndroidItemImpel extends StatefulWidget {
  const WebviewAndroidItemImpel({super.key});

  @override
  State<WebviewAndroidItemImpel> createState() =>
      _WebviewAndroidItemImpelState();
}

class _WebviewAndroidItemImpelState extends State<WebviewAndroidItemImpel> {
  late final WebviewAndroidItemControllerImpel webviewAndroidItemController;

  @override
  void initState() {
    super.initState();
    webviewAndroidItemController =
        Get.find<WebviewItemController>() as WebviewAndroidItemControllerImpel;
    webviewAndroidItemController.init();
  }

  @override
  void dispose() {
    webviewAndroidItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.width * 9.0 / (16.0),
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: const Center(child: Text('此平台不支持Webview规则', style: TextStyle(color: Colors.white))));
  }
}

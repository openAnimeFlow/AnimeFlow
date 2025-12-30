import 'package:anime_flow/pages/settings/setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PlaybackSettingsPage extends StatelessWidget {
  const PlaybackSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingController = Get.find<SettingController>();

    return Obx(() => Scaffold(
          appBar: AppBar(
            title: const Text("播放设置(开发中)"),
            automaticallyImplyLeading: !settingController.isWideScreen.value,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.construction, size: 200),
                    Text(
                      "施工中",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }
}

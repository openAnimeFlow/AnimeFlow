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
        children: [
          ListTile(
            title: const Text("默认清晰度"),
            subtitle: const Text("选择默认播放清晰度"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现清晰度设置
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("自动跳过片头片尾"),
            subtitle: const Text("自动跳过片头和片尾"),
            value: false,
            onChanged: (value) {
              // TODO: 实现跳过片头片尾设置
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("播放速度"),
            subtitle: const Text("默认播放速度"),
            trailing: const Text("1.0x"),
            onTap: () {
              // TODO: 实现播放速度设置
            },
          ),
        ],
      ),
    ));
  }
}


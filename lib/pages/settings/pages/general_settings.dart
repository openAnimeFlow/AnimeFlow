import 'package:anime_flow/pages/settings/setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingController = Get.find<SettingController>();
    
    return Obx(() => Scaffold(
      appBar: AppBar(
        title: const Text("通用设置(开发中)"),
        automaticallyImplyLeading: !settingController.isWideScreen.value,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text("主题"),
            subtitle: const Text("选择应用主题"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现主题设置
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("语言"),
            subtitle: const Text("选择应用语言"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 实现语言设置
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("自动播放"),
            subtitle: const Text("自动播放下一集"),
            value: false,
            onChanged: (value) {
              // TODO: 实现自动播放设置
            },
          ),
        ],
      ),
    ));
  }
}


import 'package:anime_flow/pages/settings/setting_controller.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingController = Get.find<SettingController>();

    return Obx(() => Scaffold(
          appBar: AppBar(
            title: const Text("关于(开发中)"),
            automaticallyImplyLeading: !settingController.isWideScreen.value,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.transparent,
                      child: AnimationNetworkImage(
                        url:
                            'https://gitee.com/anime-flow/anime-flow-assets/raw/master/logo.png',
                      ),
                    ),
                    const Text(
                      "AnimeFlow",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "版本 1.0.1",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              ListTile(
                title: const Text("检查更新"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 实现检查更新
                },
              ),
              const Divider(),
              ListTile(
                title: const Text("开源地址"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final uri =
                      Uri.parse('https://github.com/openAnimeFlow/AnimeFlow');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    Get.snackbar('无法打开网页', '你的设备可能不支持此功能');
                  }
                },
              ),
              const Divider(),
              ListTile(
                title: const Text("隐私政策"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 显示隐私政策
                },
              ),
            ],
          ),
        ));
  }
}

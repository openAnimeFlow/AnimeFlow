import 'package:anime_flow/controllers/app/app_info_controller.dart';
import 'package:anime_flow/controllers/setting_controller.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingController = Get.find<SettingController>();
    final appInfoController = Get.find<AppInfoController>();
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: const Text("关于"),
          automaticallyImplyLeading: !settingController.isWideScreen.value,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Obx(
              () => Center(
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
                    Text(
                      appInfoController.appName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '版本 ${appInfoController.version}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            ListTile(
              title: const Text("检查更新"),
              trailing: const Icon(Icons.browser_updated_outlined),
              onTap: () {
                appInfoController.compareVersion();
              },
            ),
            const Divider(),
            ListTile(
              title: const Text("开源地址"),
              trailing: const Icon(Icons.open_in_new),
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
              title: const Text("鸣谢"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed(RouteName.settingThanks);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text("隐私政策"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.toNamed(RouteName.settingAgreement);
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    const Text(
                      '交流群:',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                    ),
                    Card(
                      elevation: 0,
                      child: IntrinsicWidth(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            final uri = Uri.parse(
                                'https://t.me/+8Sc45kSCIlkzODNl');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              Get.snackbar('无法打开网页', '你的设备可能不支持此功能');
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.telegram_sharp,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                                Text('telegram',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

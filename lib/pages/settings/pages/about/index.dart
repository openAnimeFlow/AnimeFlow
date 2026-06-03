import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/features/app/app_info_provider.dart';
import 'package:anime_flow/widget/version_update_ui.dart';
import 'package:anime_flow/pages/settings/setting_provider.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettingsPage extends ConsumerStatefulWidget {
  const AboutSettingsPage({super.key});

  @override
  ConsumerState<AboutSettingsPage> createState() => _AboutSettingsPageState();
}

class _AboutSettingsPageState extends ConsumerState<AboutSettingsPage> {
  final setting = Storage.setting;
  late bool autoUpdate;

  @override
  void initState() {
    super.initState();
    autoUpdate = setting.get(StorageKey.autoUpdateKey, defaultValue: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: const Text('关于'),
              automaticallyImplyLeading: !isWideScreen,
            );
          },
        ),
      ),
      body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Consumer(
              builder: (context, ref, _) {
                final appInfo = ref.watch(appInfoProvider);
                return Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.transparent,
                        child: Image.asset(
                          AssetsPathConstants.logo,
                        ),
                      ),
                      Text(
                        appInfo.appName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '版本 ${appInfo.version}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("自动更新"),
                    Switch(
                      value: autoUpdate,
                      onChanged: (bool value) {
                        setState(() {
                          setting.put(StorageKey.autoUpdateKey, value);
                          autoUpdate = value;
                        });
                      },
                    ),
                  ]),
            ),
            const Divider(),
            ListTile(
              title: const Text("检查更新"),
              trailing: const Icon(Icons.browser_updated_outlined),
              onTap: () async {
                final notifier = ref.read(appInfoProvider.notifier);
                final result = await notifier.checkVersion();
                if (!context.mounted) return;
                await handleVersionCheckResult(
                  context,
                  result,
                  onStartDownload: notifier.performUpdateDownload,
                  onCancelDownload: notifier.cancelUpdateDownload,
                  notifyWhenUpToDate: true,
                );
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
                  NotificationToast.show('无法打开网页', '你的设备可能不支持此功能');
                }
              },
            ),
            const Divider(),
            ListTile(
              title: const Text("鸣谢"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                const SettingThanksRoute().push(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text("隐私政策"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                const SettingAgreementRoute().push(context);
              },
            ),
            const Divider(),
          ],
        ),
    );
  }
}

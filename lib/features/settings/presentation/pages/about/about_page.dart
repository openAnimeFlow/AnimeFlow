import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/features/app_update/application/app_info_provider.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/features/app_update/presentation/widgets/version_update_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: Text(l10n.about),
              automaticallyImplyLeading: !isWideScreen,
              backgroundColor: Colors.transparent,
            );
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final appInfo = ref.watch(appInfoProvider);
              final colorScheme = Theme.of(context).colorScheme;
              final topPadding =
                  MediaQuery.paddingOf(context).top + kToolbarHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0, 0.68, 1],
                      ).createShader(bounds),
                      child: SvgPicture.asset(
                        AssetsPathConstants.ambientWaveBackground,
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          colorScheme.primary.withValues(alpha: 0.42),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      topPadding + 28,
                      16,
                      44,
                    ),
                    child: Center(
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
                            l10n.version(appInfo.version),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.autoUpdate),
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
                  title: Text(l10n.checkForUpdates),
                  trailing: const Icon(Icons.browser_updated_outlined),
                  onTap: () async {
                    final notifier = ref.read(appInfoProvider.notifier);
                    final result = await notifier.checkVersion();
                    if (!context.mounted) return;
                    await handleVersionCheckResult(
                      context,
                      result,
                      onStartDownload: notifier.performUpdateDownload,
                      onDownloadedPackageAction: notifier.openDownloadedPackage,
                      onCancelDownload: notifier.cancelUpdateDownload,
                      notifyWhenUpToDate: true,
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n.projectUpdates),
                  trailing: const Icon(Icons.article_outlined),
                  onTap: () => const SettingUpdatesRoute().push(context),
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n.openSource),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final uri = Uri.parse(Constants.animeFlow);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      NotificationToast.show(l10n.deviceUnsupportedWeb,
                          title: l10n.unableOpenWeb);
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n.thanks),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    const SettingThanksRoute().push(context);
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n.privacyPolicy),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    const SettingAgreementRoute().push(context);
                  },
                ),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

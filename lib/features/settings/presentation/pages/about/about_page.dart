import 'package:anime_flow/shared/widgets/adaptive_app_bar.dart';
import 'package:anime_flow/shared/models/version_check_result.dart';
import 'package:anime_flow/features/settings/presentation/widgets/settings_page_builder.dart';
import 'package:anime_flow/shared/navigation/settings_destination.dart';
import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/features/app_update/application/app_info_provider.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/features/app_update/presentation/widgets/version_update_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';

class AboutSettingsPage extends StatefulWidget {
  const AboutSettingsPage({super.key});

  @override
  State<AboutSettingsPage> createState() => _AboutSettingsPageState();
}

class _AboutSettingsPageState extends State<AboutSettingsPage> {
  late bool autoUpdate;
  bool _checkingForUpdates = false;

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    if (_checkingForUpdates) return;
    final notifier = ref.read(appInfoProvider.notifier);
    setState(() => _checkingForUpdates = true);
    final VersionCheckResult result;
    try {
      result = await notifier.checkVersion();
    } finally {
      if (mounted) setState(() => _checkingForUpdates = false);
    }
    if (!context.mounted) return;
    await handleVersionCheckResult(
      context,
      result,
      onStartDownload: notifier.performUpdateDownload,
      onDownloadedPackageAction: notifier.openDownloadedPackage,
      onCancelDownload: notifier.cancelUpdateDownload,
      notifyWhenUpToDate: true,
    );
  }

  @override
  void initState() {
    super.initState();
    autoUpdate = AppSettings.autoUpdate;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final paddingOf = MediaQuery.paddingOf(context);
    final topPadding = paddingOf.top + kToolbarHeight;
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      child: SettingsPageBuilder(
          builder: (context, glassStyle) => Scaffold(
                extendBodyBehindAppBar: true,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final isWideScreen = ref.watch(settingsLayoutProvider);
                      return AdaptiveAppBar(
                        glassStyle: glassStyle,
                        title: Text(l10n.about),
                        automaticallyImplyLeading: !isWideScreen,
                        backgroundColor: Colors.transparent,
                      );
                    },
                  ),
                ),
                body: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: SizedBox(
                          height: 360,
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
                      ),
                    ),
                    SingleChildScrollView(
                      padding: EdgeInsets.only(
                          top: topPadding, bottom: paddingOf.bottom),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1500),
                          child: Column(
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
                                          l10n.version(appInfo.version),
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(l10n.autoUpdate),
                                            Switch(
                                              value: autoUpdate,
                                              onChanged: (bool value) {
                                                setState(() {
                                                  AppSettings.setAutoUpdate(
                                                      value);
                                                  autoUpdate = value;
                                                });
                                              },
                                            ),
                                          ]),
                                    ),
                                    const Divider(),
                                    Consumer(
                                      builder: (context, ref, _) {
                                        return ListTile(
                                          title: Text(_checkingForUpdates
                                              ? l10n.checkingForUpdates
                                              : l10n.checkForUpdates),
                                          enabled: !_checkingForUpdates,
                                          trailing: _checkingForUpdates
                                              ? SizedBox.square(
                                                  dimension: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    semanticsLabel:
                                                        l10n.checkingForUpdates,
                                                  ),
                                                )
                                              : const Icon(Icons
                                                  .browser_updated_outlined),
                                          onTap: _checkingForUpdates
                                              ? null
                                              : () => _checkForUpdates(
                                                  context, ref),
                                        );
                                      },
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: Text(l10n.projectUpdates),
                                      trailing:
                                          const Icon(Icons.article_outlined),
                                      onTap: () => appNavigatorOf(context)
                                          .openSettings<void>(
                                              destination:
                                                  SettingsDestination.updates),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: Text(l10n.projectWebsite),
                                      trailing:
                                          const Icon(Icons.public_outlined),
                                      onTap: () => appNavigatorOf(context)
                                          .openSettings<void>(
                                              destination:
                                                  SettingsDestination.website),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: Text(l10n.openSource),
                                      trailing: const Icon(Icons.open_in_new),
                                      onTap: () async {
                                        final uri =
                                            Uri.parse(Constants.animeFlow);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          NotificationToast.show(
                                              l10n.deviceUnsupportedWeb,
                                              title: l10n.unableOpenWeb);
                                        }
                                      },
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: Text(l10n.thanks),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        appNavigatorOf(context)
                                            .openSettings<void>(
                                                destination:
                                                    SettingsDestination.thanks);
                                      },
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: const Text('关于作者'),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => appNavigatorOf(context)
                                          .openSettings<void>(
                                              destination:
                                                  SettingsDestination.author),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: Text(l10n.sponsor),
                                      trailing: const Icon(
                                        Icons.volunteer_activism_outlined,
                                      ),
                                      onTap: () {
                                        appNavigatorOf(context)
                                            .openSettings<void>(
                                                destination: SettingsDestination
                                                    .sponsor);
                                      },
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: Text(l10n.privacyPolicy),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        appNavigatorOf(context)
                                            .openSettings<void>(
                                                destination: SettingsDestination
                                                    .agreement);
                                      },
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
    );
  }
}

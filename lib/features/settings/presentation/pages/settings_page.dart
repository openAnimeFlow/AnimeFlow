import 'package:anime_flow/features/settings/presentation/pages/danmaku_setting_page.dart';
import 'package:anime_flow/features/settings/presentation/pages/plugins/plugins.dart';
import 'package:anime_flow/features/settings/presentation/pages/theme.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/settings/presentation/pages/account_settings_page.dart';
import 'package:anime_flow/features/settings/presentation/pages/general_settings.dart';
import 'package:anime_flow/features/settings/presentation/pages/playback_settings.dart';
import 'package:anime_flow/features/settings/presentation/pages/about/about_page.dart';
import 'package:anime_flow/features/settings/presentation/pages/error_logs_page.dart';

///设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;
  bool? _syncedIsWideScreen;

  List<_SettingsCategory> _categories(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      _SettingsCategory(
        title: l10n.userInfoSettings,
        items: [
          _SettingsMenuItem(
            title: l10n.accountSettings,
            icon: Icons.account_circle_outlined,
            route: const SettingAccountRoute(),
            page: const AccountSettingsPage(),
          ),
        ],
      ),
      _SettingsCategory(
        title: l10n.appAppearance,
        items: [
          _SettingsMenuItem(
            title: l10n.generalSettingsTitle,
            icon: Icons.settings_outlined,
            route: const SettingGeneralRoute(),
            page: const GeneralSettingsPage(),
          ),
          _SettingsMenuItem(
            title: l10n.themeStyle,
            icon: Icons.color_lens_outlined,
            route: const SettingThemeRoute(),
            page: const ThemePage(),
          ),
        ],
      ),
      _SettingsCategory(
        title: l10n.playbackHistoryVideoSource,
        items: [
          _SettingsMenuItem(
            title: l10n.sourceManagement,
            icon: Icons.smart_display_rounded,
            route: const SettingPluginsRoute(),
            page: const PluginsPage(),
          ),
        ],
      ),
      _SettingsCategory(
        title: l10n.playerSettings,
        items: [
          _SettingsMenuItem(
            title: l10n.playbackSettings,
            icon: Icons.play_circle_outline,
            route: const SettingPlaybackRoute(),
            page: const PlaybackSettingsPage(),
          ),
          _SettingsMenuItem(
            title: l10n.danmakuSettings,
            icon: Icons.subtitles_outlined,
            route: const SettingDanmakuRoute(),
            page: const DanmakuSettingPage(),
          ),
        ],
      ),
      _SettingsCategory(
        title: l10n.otherSettings,
        items: [
          _SettingsMenuItem(
            title: l10n.errorLogs,
            icon: Icons.receipt_long_outlined,
            route: const SettingLogsRoute(),
            page: const ErrorLogsPage(),
          ),
          _SettingsMenuItem(
            title: l10n.about,
            icon: Icons.info_outline,
            route: const SettingAboutRoute(),
            page: const AboutSettingsPage(),
          ),
        ],
      )
    ];
  }

  void _syncWideScreenIfNeeded(WidgetRef ref, bool isWideScreen) {
    if (_syncedIsWideScreen == isWideScreen) return;
    _syncedIsWideScreen = isWideScreen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(settingsLayoutProvider.notifier).setWideScreen(isWideScreen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWideScreen = constraints.maxWidth > 600;
            _syncWideScreenIfNeeded(ref, isWideScreen);
            return isWideScreen
                ? buildWideLayout(context)
                : buildNarrowLayout(context);
          },
        );
      },
    );
  }

  Widget buildWideLayout(BuildContext context) {
    final categories = _categories(context);
    final allMenuItems =
        categories.expand((category) => category.items).toList();
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.arrow_back),
                      title: Text(AppLocalizations.of(context).settingsLabel),
                      onTap: () => context.pop(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      left: MediaQuery.of(context).padding.left +
                          (SystemUtil.isDesktop ? 15 : 0),
                      right: 15,
                    ),
                    children: [
                      ...categories.map((category) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 10,
                              ),
                              child: Text(
                                category.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            ...category.items.map((item) {
                              final globalIndex = allMenuItems.indexOf(item);
                              final isSelected = globalIndex == _selectedIndex;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = globalIndex;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(50),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 3,
                                      horizontal: 3,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item.icon,
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: allMenuItems[_selectedIndex].page,
          ),
        ],
      ),
    );
  }

  Widget buildNarrowLayout(BuildContext context) {
    final categories = _categories(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settingsLabel),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: categories.map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  category.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              ...category.items.map((item) {
                return ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    item.route.push(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsCategory {
  final String title;
  final List<_SettingsMenuItem> items;

  _SettingsCategory({
    required this.title,
    required this.items,
  });
}

class _SettingsMenuItem {
  final String title;
  final IconData icon;
  final GoRouteData route;
  final Widget page;

  _SettingsMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.page,
  });
}

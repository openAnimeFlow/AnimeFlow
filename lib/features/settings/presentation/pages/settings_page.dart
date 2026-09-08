import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/features/settings/presentation/pages/account_settings_page.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Responsive shell around the settings route navigator.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 600;
          return ProviderScope(
            overrides: [settingsLayoutProvider.overrideWithValue(wide)],
            child: wide
                ? Scaffold(
                    body: Row(children: [
                    SizedBox(
                        width: 250,
                        child: _SettingsMenu(location: location, wide: true)),
                    Expanded(child: child),
                  ]))
                : child,
          );
        },
      );
}

/// Root settings route: menu on narrow screens, default category on wide screens.
class SettingsMenuPage extends ConsumerWidget {
  const SettingsMenuPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(settingsLayoutProvider)
          ? const AccountSettingsPage()
          : Scaffold(
              appBar: AppBar(
                  title: Text(AppLocalizations.of(context).settingsLabel)),
              body: const _SettingsMenu(location: '/settings', wide: false),
            );
}

class _SettingsMenu extends StatelessWidget {
  const _SettingsMenu({required this.location, required this.wide});
  final String location;
  final bool wide;

  String get categoryLocation => switch (location) {
        '/settings' => '/settings/account',
        '/settings/font' => '/settings/theme',
        '/settings/addPlugins' ||
        '/settings/downloadPlugins' =>
          '/settings/Plugins',
        '/settings/thanks' || '/settings/agreement' => '/settings/about',
        _ => location,
      };

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
          ),
          _SettingsMenuItem(
            title: l10n.themeStyle,
            icon: Icons.color_lens_outlined,
            route: const SettingThemeRoute(),
          ),
        ],
      ),
      _SettingsCategory(
        title: l10n.playbackResources,
        items: [
          _SettingsMenuItem(
            title: l10n.sourceManagement,
            icon: Icons.smart_display_outlined,
            route: const SettingPluginsRoute(),
          ),
          _SettingsMenuItem(
            title: l10n.downloadSettings,
            icon: Icons.cloud_download_outlined,
            route: const SettingDownloadRoute(),
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
          ),
          _SettingsMenuItem(
            title: l10n.danmakuSettings,
            icon: Icons.subtitles_outlined,
            route: const SettingDanmakuRoute(),
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
          ),
          _SettingsMenuItem(
            title: l10n.about,
            icon: Icons.info_outline,
            route: const SettingAboutRoute(),
          ),
        ],
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories(context);
    final menu = ListView(
      padding: EdgeInsets.symmetric(horizontal: wide ? 15 : 0, vertical: 8),
      children: [
        for (final category in categories) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(category.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )),
          ),
          for (final item in category.items)
            ListTile(
              shape: wide ? const StadiumBorder() : null,
              selected: wide && categoryLocation == item.route.location,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              leading: Icon(item.icon),
              title: Text(item.title),
              trailing: wide ? null : const Icon(Icons.chevron_right),
              onTap: () {
                if (wide) {
                  if (location != item.route.location) {
                    item.route.replace(context);
                  }
                } else {
                  item.route.push(context);
                }
              },
            ),
          const SizedBox(height: 8),
        ]
      ],
    );
    if (!wide) return menu;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        right: false,
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: Text(AppLocalizations.of(context).settingsLabel),
            onTap: () {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                const RecommendRoute().go(context);
              }
            },
          ),
          const Divider(height: 1),
          Expanded(
              child: Padding(
            padding: EdgeInsets.only(left: SystemUtil.isDesktop ? 15 : 0),
            child: menu,
          )),
        ]),
      ),
    );
  }
}

class _SettingsCategory {
  const _SettingsCategory({required this.title, required this.items});
  final String title;
  final List<_SettingsMenuItem> items;
}

class _SettingsMenuItem {
  const _SettingsMenuItem(
      {required this.title, required this.icon, required this.route});
  final String title;
  final IconData icon;
  final GoRouteData route;
}

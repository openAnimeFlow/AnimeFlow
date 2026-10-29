import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/settings_destination.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/features/settings/presentation/pages/account_settings_page.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/features/user/user_api.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void _exitSettings(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    appNavigatorOf(context).goToRecommend(context);
  }
}

/// Responsive shell around the settings route navigator.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    // Reuse the same widget while resizing within a layout breakpoint.
    final narrow =
        _SettingsLayout(wide: false, location: location, child: child);
    final wide = _SettingsLayout(wide: true, location: location, child: child);
    return LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth > 600 ? wide : narrow);
  }
}

class _SettingsLayout extends StatelessWidget {
  const _SettingsLayout(
      {required this.wide, required this.location, required this.child});

  final bool wide;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: [settingsLayoutProvider.overrideWithValue(wide)],
        // Keep the route navigator at the same position in both layouts.
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Row(children: [
            SizedBox(
                width: wide ? 250 : 0,
                child: wide
                    ? _SettingsMenu(location: location, wide: true)
                    : null),
            Expanded(child: child),
          ]),
        ),
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
                  leading: BackButton(onPressed: () => _exitSettings(context)),
                  title: Text(AppLocalizations.of(context).settings)),
              body: _SettingsMenu(
                  location: appNavigatorOf(context)
                      .settingsLocation(SettingsDestination.menu),
                  wide: false),
            );
}

class _SettingsMenu extends ConsumerWidget {
  const _SettingsMenu({required this.location, required this.wide});

  final String location;
  final bool wide;

  SettingsDestination? _category(SettingsDestination? destination) =>
      switch (destination) {
        SettingsDestination.menu => SettingsDestination.account,
        SettingsDestination.font => SettingsDestination.theme,
        SettingsDestination.addPlugins ||
        SettingsDestination.downloadPlugins =>
          SettingsDestination.plugins,
        SettingsDestination.thanks ||
        SettingsDestination.author ||
        SettingsDestination.website ||
        SettingsDestination.sponsor ||
        SettingsDestination.agreement =>
          SettingsDestination.about,
        _ => destination,
      };

  List<_SettingsCategory> _categories(BuildContext context, String? avatar) {
    final l10n = AppLocalizations.of(context);
    return [
      _SettingsCategory(
        title: l10n.userInfoSettings,
        items: [
          _SettingsMenuItem(
            title: l10n.accountSettings,
            icon: Icons.account_circle_outlined,
            avatar: avatar,
            destination: SettingsDestination.account,
          ),
        ],
      ),
      _SettingsCategory(
        title: l10n.appAppearance,
        items: [
          _SettingsMenuItem(
            title: l10n.generalSettingsTitle,
            icon: Icons.settings_outlined,
            destination: SettingsDestination.general,
          ),
          _SettingsMenuItem(
            title: l10n.themeStyle,
            icon: Icons.color_lens_outlined,
            destination: SettingsDestination.theme,
          ),
          _SettingsMenuItem(
            title: l10n.pageSettings,
            icon: Icons.web_outlined,
            destination: SettingsDestination.page,
          ),
        ],
      ),
      _SettingsCategory(
        title: l10n.playbackResources,
        items: [
          _SettingsMenuItem(
            title: l10n.sourceManagement,
            icon: Icons.smart_display_outlined,
            destination: SettingsDestination.plugins,
          ),
          _SettingsMenuItem(
            title: l10n.downloadSettings,
            icon: Icons.cloud_download_outlined,
            destination: SettingsDestination.download,
          ),
        ],
      ),
      _SettingsCategory(
        title: l10n.playerSettings,
        items: [
          _SettingsMenuItem(
            title: l10n.playbackSettings,
            icon: Icons.play_circle_outline,
            destination: SettingsDestination.playback,
          ),
          if (SystemUtil.isDesktop)
            _SettingsMenuItem(
              title: l10n.playerShortcuts,
              icon: Icons.keyboard_outlined,
              destination: SettingsDestination.playerShortcuts,
            ),
          _SettingsMenuItem(
            title: l10n.danmakuSettings,
            icon: Icons.subtitles_outlined,
            destination: SettingsDestination.danmaku,
          ),
        ],
      ),
      _SettingsCategory(
        title: l10n.otherSettings,
        items: [
          _SettingsMenuItem(
            title: l10n.errorLogs,
            icon: Icons.receipt_long_outlined,
            destination: SettingsDestination.logs,
          ),
          _SettingsMenuItem(
            title: l10n.about,
            icon: Icons.info_outline,
            destination: SettingsDestination.about,
          ),
        ],
      )
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paddingOf = MediaQuery.paddingOf(context);
    final userInfo = ref.watch(currentUserInfoProvider).value;
    final isLoggedIn = ref.watch(isLoggedInProvider).value ?? false;
    final avatar = isLoggedIn && (userInfo?.avatar?.isNotEmpty ?? false)
        ? userInfo!.avatar
        : null;
    final categories = _categories(context, avatar);
    final navigation = appNavigatorOf(context);
    final currentDestination =
        navigation.settingsDestinationForLocation(location);
    final menu = ListView(
      padding: EdgeInsets.only(
        left: wide ? 15 : 0,
        right: wide ? 15 : 0,
        top: 8,
        bottom: wide ? 8 : paddingOf.bottom,
      ),
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
              selected:
                  wide && _category(currentDestination) == item.destination,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              leading: item.avatar != null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      position: DecorationPosition.foreground,
                      child: AnimationNetworkImage(
                        borderRadius: BorderRadius.circular(50),
                        url: item.avatar!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(item.icon),
              title: Text(item.title),
              trailing: wide ? null : const Icon(Icons.chevron_right),
              onTap: () {
                if (wide && currentDestination != SettingsDestination.menu) {
                  if (currentDestination != item.destination) {
                    navigation.replaceSettings(context, item.destination);
                  }
                } else {
                  navigation.openSettings<void>(context,
                      destination: item.destination);
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
            title: Text(AppLocalizations.of(context).settings),
            onTap: () {
              _exitSettings(context);
            },
          ),
          const Divider(height: 1),
          Expanded(
              child: Material(
            type: MaterialType.transparency,
            clipBehavior: Clip.hardEdge,
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
      {required this.title,
      required this.icon,
      required this.destination,
      this.avatar});

  final String title;
  final IconData icon;
  final SettingsDestination destination;
  final String? avatar;
}

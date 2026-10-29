import 'package:anime_flow/features/shell/presentation/widgets/shell_navigation_tabs.dart';
import 'package:anime_flow/features/shell/presentation/widgets/shell_navigation_rail.dart';
import 'package:anime_flow/features/shell/presentation/widgets/shell_bottom_navigation.dart';
import 'package:anime_flow/features/shell/presentation/widgets/glass_navigation_bar.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/shared/widgets/bottom_occlusion.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/settings_destination.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/user/user_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

/// 主页面 — 使用 [StatefulNavigationShell] 管理三个 Tab 分支页面。
class AppShellPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShellPage({super.key, required this.navigationShell});

  String? _avatar(WidgetRef ref) {
    final userInfo = ref.watch(currentUserInfoProvider).value;
    final isLoggedIn = ref.watch(isLoggedInProvider).value ?? false;
    return isLoggedIn && (userInfo?.avatar?.isNotEmpty ?? false)
        ? userInfo!.avatar
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 640;
      if (isDesktop) {
        return _buildScaffold(context, isDesktop: true, glassBar: false);
      } else {
        return StreamBuilder<bool>(
          stream: AppSettings.watchGlassNavigationBar(),
          initialData: AppSettings.glassNavigationBar,
          builder: (context, snapshot) => _buildScaffold(context,
              isDesktop: false, glassBar: snapshot.data ?? false),
        );
      }
    });
  }

  Widget _buildScaffold(BuildContext context,
      {required bool isDesktop, required bool glassBar}) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBody: glassBar,
      backgroundColor: isDesktop ? colorScheme.surfaceContainerHighest : null,
      body: Row(
        children: [
          if (isDesktop)
            Consumer(
                builder: (context, ref, _) => ShellNavigationRail(
                      tabs: shellNavigationTabs(l10n),
                      avatar: _avatar(ref),
                      selectedIndex: navigationShell.currentIndex,
                      onSelected: navigationShell.goBranch,
                      onSearch: () =>
                          appNavigatorOf(context).openSearch<void>(context),
                      onSettings: () =>
                          appNavigatorOf(context).openSettings<void>(
                        context,
                        destination: SettingsDestination.menu,
                      ),
                    )),
          Expanded(
            child: ClipRRect(
              borderRadius: isDesktop
                  ? const BorderRadius.horizontal(left: Radius.circular(16))
                  : BorderRadius.zero,
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Builder(builder: (context) {
                  // extendBody 提供的底部 padding 包含悬浮导航栏的实际高度。
                  return BottomOcclusionScope(
                    height: glassBar ? MediaQuery.paddingOf(context).bottom : 0,
                    child: navigationShell,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Consumer(builder: (context, ref, _) {
              final tabs = shellNavigationTabs(l10n);
              final avatar = _avatar(ref);
              if (glassBar) {
                return SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  maintainBottomViewPadding: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GlassNavigationBar(
                      tabs: tabs,
                      avatar: avatar,
                      selectedIndex: navigationShell.currentIndex,
                      onSelected: navigationShell.goBranch,
                    ),
                  ),
                );
              }
              return ShellBottomNavigation(
                tabs: tabs,
                avatar: avatar,
                selectedIndex: navigationShell.currentIndex,
                onSelected: navigationShell.goBranch,
              );
            }),
    );
  }
}

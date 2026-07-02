import 'package:anime_flow/models/item/tab_item.dart';
import 'package:anime_flow/pages/login/index.dart';
import 'package:anime_flow/pages/user/index.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:anime_flow/widget/drop_down_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 主页面 — 使用 [StatefulNavigationShell] 管理三个 Tab 分支页面。
/// 桌面端使用 [NavigationRail]，移动端使用 [NavigationBar]。
class MainPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainPage({super.key, required this.navigationShell});

  static final List<TabItem> _tabs = [
    TabItem(
      title: "推荐",
      icon: Icons.smart_display_outlined,
      activeIcon: Icons.smart_display_rounded,
    ),
    TabItem(
      title: "排行",
      icon: Icons.leaderboard_outlined,
      activeIcon: Icons.leaderboard_rounded,
    ),
    TabItem(
      title: "我的",
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  List<NavigationRailDestination> _buildRailDestinations(
    ColorScheme colorScheme,
    String? avatar,
  ) {
    return _tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;

      if (index == 2 && avatar != null) {
        return NavigationRailDestination(
          icon: AnimationNetworkImage(
            borderRadius: BorderRadius.circular(50),
            url: avatar,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
          ),
          selectedIcon: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: AnimationNetworkImage(
              borderRadius: BorderRadius.circular(50),
              url: avatar,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
          ),
          label: Text(tab.title),
        );
      }
      return NavigationRailDestination(
        icon: Icon(tab.icon),
        selectedIcon: Icon(tab.activeIcon, color: colorScheme.primary),
        label: Text(tab.title),
      );
    }).toList();
  }

  List<NavigationDestination> _buildBarDestinations(
    ColorScheme colorScheme,
    String? avatar,
  ) {
    return _tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      if (index == 2 && avatar != null) {
        return NavigationDestination(
          icon: AnimationNetworkImage(
            borderRadius: BorderRadius.circular(50),
            url: avatar,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
          ),
          selectedIcon: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: AnimationNetworkImage(
              borderRadius: BorderRadius.circular(50),
              url: avatar,
              width: 24,
              height: 24,
              fit: BoxFit.fill,
            ),
          ),
          label: tab.title,
        );
      }

      return NavigationDestination(
        icon: Icon(tab.icon),
        selectedIcon: Icon(tab.activeIcon, color: colorScheme.primary),
        label: tab.title,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 640;
    final colorScheme = Theme.of(context).colorScheme;
    final desktop = SystemUtil.isDesktop;
    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            Consumer(
              builder: (context, ref, _) {
                final userInfo = ref.watch(currentUserInfoProvider).value;
                final isLoggedIn = ref.watch(isLoggedInProvider).value ?? false;
                final avatar =
                    isLoggedIn && (userInfo?.avatar?.isNotEmpty ?? false)
                        ? userInfo!.avatar
                        : null;
                return NavigationRail(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  selectedIndex: navigationShell.currentIndex,
                  groupAlignment: 1.0,
                  onDestinationSelected: navigationShell.goBranch,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                    child: FloatingActionButton(
                      heroTag: 'main_search',
                      elevation: 0,
                      onPressed: () {
                        const SearchRoute().push(context);
                      },
                      child: const Icon(Icons.search),
                    ),
                  ),
                  trailing: Padding(
                    padding: EdgeInsets.only(
                        bottom: desktop
                            ? 16
                            : MediaQuery.of(context).padding.bottom),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      iconSize: 28,
                      tooltip: '设置',
                      onPressed: () => const SettingsRoute().push(context),
                    ),
                  ),
                  destinations: _buildRailDestinations(colorScheme, avatar),
                );
              },
            ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Consumer(
              builder: (context, ref, _) {
                final userInfo = ref.watch(currentUserInfoProvider).value;
                final isLoggedIn = ref.watch(isLoggedInProvider).value ?? false;
                final avatar =
                    isLoggedIn && (userInfo?.avatar?.isNotEmpty ?? false)
                        ? userInfo!.avatar
                        : null;
                return NavigationBar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: navigationShell.goBranch,
                  destinations: _buildBarDestinations(colorScheme, avatar),
                );
              },
            ),
    );
  }
}

/// 用户 Tab 页 — 已登录显示 [UserPage]，未登录显示 [LoginPage]。
class UserTabPage extends ConsumerWidget {
  const UserTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedInAsync = ref.watch(isLoggedInProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return isLoggedInAsync.when(
      data: (isLoggedIn) => isLoggedIn
          ? const UserPage()
          : LoginPage(
              appBar: AppBar(
                forceMaterialTransparency: true,
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropDownMenu<_NoLoginOverflowAction>(
                      tooltip: '更多菜单',
                      items: _NoLoginOverflowAction.values,
                      disableSelected: false,
                      buttonBuilder: (context, _) => Icon(
                        Icons.notes_outlined,
                        size: 28,
                        color: colorScheme.onSurface,
                      ),
                      itemBuilder: (context, action, _) {
                        final (icon, label) = switch (action) {
                          _NoLoginOverflowAction.settings => (
                              Icons.settings_outlined,
                              '设置'
                            ),
                          _NoLoginOverflowAction.playRecord => (
                              Icons.smart_display_outlined,
                              '播放记录'
                            ),
                        };
                        return SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(label,
                                  style: Theme.of(context).textTheme.bodyLarge),
                            ],
                          ),
                        );
                      },
                      onSelected: (action) {
                        switch (action) {
                          case _NoLoginOverflowAction.settings:
                            const SettingsRoute().push(context);
                          case _NoLoginOverflowAction.playRecord:
                            const PlayRecordRoute().push(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const LoginPage(),
    );
  }
}

enum _NoLoginOverflowAction { settings, playRecord }

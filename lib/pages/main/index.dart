import 'package:anime_flow/providers/user/my_state_provider.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/models/item/tab_item.dart';
import 'package:anime_flow/pages/ranking/index.dart';
import 'package:anime_flow/pages/user/index.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/pages/recommend/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class MainPage extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const MainPage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 0;

  final GlobalKey _bodyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex.clamp(0, _tabs.length - 1);
    initializePage(_currentIndex);
  }

  final List<TabItem> _tabs = [
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

  final List<Widget?> _pageCache = List.filled(3, null);

  void initializePage(int index) {
    if (_pageCache[index] == null) {
      switch (index) {
        case 0:
          _pageCache[index] = const RecommendPage();
          break;
        case 1:
          _pageCache[index] = const RankingPage();
          break;
        case 2:
          _pageCache[index] = const UserPage();
          break;
      }
    }
  }

  List<NavigationRailDestination> buildRailDestinations(
    ColorScheme colorScheme,
    UserInfoItem? userInfo,
  ) {
    return _tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;

      if (index == 2 && userInfo != null) {
        return NavigationRailDestination(
          icon: AnimationNetworkImage(
            borderRadius: BorderRadius.circular(50),
            url: userInfo.avatar.medium,
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
              url: userInfo.avatar.medium,
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

  List<NavigationDestination> buildBarDestinations(
    ColorScheme colorScheme,
    UserInfoItem? userInfo,
  ) {
    return _tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      if (index == 2 && userInfo != null) {
        return NavigationDestination(
          icon: AnimationNetworkImage(
            borderRadius: BorderRadius.circular(50),
            url: userInfo.avatar.medium,
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
              url: userInfo.avatar.medium,
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

  void onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
      initializePage(index);
    });
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
                final userInfo = ref.watch(currentUserInfoProvider);
                return NavigationRail(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  selectedIndex: _currentIndex,
                  groupAlignment: 1.0,
                  onDestinationSelected: onDestinationSelected,
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
                  destinations:
                      buildRailDestinations(colorScheme, userInfo),
                );
              },
            ),
          Expanded(
            child: IndexedStack(
              key: _bodyKey,
              index: _currentIndex,
              children:
                  _pageCache.map((e) => e ?? const SizedBox.shrink()).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Consumer(
              builder: (context, ref, _) {
                final userInfo = ref.watch(currentUserInfoProvider);
                return NavigationBar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations:
                      buildBarDestinations(colorScheme, userInfo),
                );
              },
            ),
    );
  }
}

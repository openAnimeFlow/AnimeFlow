import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/controllers/app/app_info_controller.dart';
import 'package:anime_flow/controllers/my_controller.dart';
import 'package:anime_flow/controllers/shaders/shaders_controller.dart';
import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/models/item/tab_item.dart';
import 'package:anime_flow/pages/my/index.dart';
import 'package:anime_flow/pages/ranking/index.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/pages/recommend/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class MainPage extends StatefulWidget {
  final int initialTabIndex;

  const MainPage({super.key, this.initialTabIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final AppInfoController appInfoController;
  late final ShadersController shadersController;
  final setting = Storage.setting;
  int _currentIndex = 0;
  late bool autoUpdate;

  final GlobalKey _bodyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    autoUpdate = setting.get(StorageKey.autoUpdateKey, defaultValue: true);
    appInfoController = Get.put(AppInfoController(), permanent: true);
    shadersController = Get.put(ShadersController(), permanent: true);

    _currentIndex =
        widget.initialTabIndex.clamp(0, _tabs.length - 1);
    _initializeApp();
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

  void _initializePage(int index) {
    if (_pageCache[index] == null) {
      switch (index) {
        case 0:
          _pageCache[index] = const RecommendPage();
          break;
        case 1:
          _pageCache[index] = const RankingPage();
          break;
        case 2:
          _pageCache[index] = const MyPage();
          break;
      }
    }
  }

  Future<void> _initializeApp() async {
    _initializePage(_currentIndex);
    CrawlConfig.initCrawlConfigs();
    if (autoUpdate) {
      appInfoController.compareVersion();
    }
    await shadersController.copyShadersToExternalDirectory();
  }

  List<NavigationRailDestination> _buildRailDestinations(
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

  List<NavigationDestination> _buildBarDestinations(
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

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
      _initializePage(index);
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
                  selectedIndex: _currentIndex,
                  groupAlignment: 1.0,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.none,
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
                      tooltip: 'Settings',
                      onPressed: () => const SettingsRoute().push(context),
                    ),
                  ),
                  destinations:
                      _buildRailDestinations(colorScheme, userInfo),
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
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                  destinations:
                      _buildBarDestinations(colorScheme, userInfo),
                );
              },
            ),
    );
  }
}

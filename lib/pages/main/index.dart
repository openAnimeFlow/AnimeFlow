import 'package:anime_flow/controllers/main_page/main_page_state.dart';
import 'package:anime_flow/models/item/tab_item.dart';
import 'package:anime_flow/pages/my/index.dart';
import 'package:anime_flow/pages/ranking/index.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:anime_flow/utils/crawl_config.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/windows_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/pages/recommend/index.dart';
import 'package:get/get.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainPageState mainPageState;
  late UserInfoStore userInfoStore;

  // 使用 GlobalKey 保持 IndexedStack 的状态，防止在布局切换（Row <-> Column）时页面重构
  final GlobalKey _bodyKey = GlobalKey();

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

  // 懒加载页面缓存
  final List<Widget?> _pageCache = List.filled(3, null);

  int _currentIndex = 0;

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

  @override
  void initState() {
    super.initState();
    mainPageState = Get.put(MainPageState());
    CrawlConfig.initCrawlConfigs();
    userInfoStore = Get.put(UserInfoStore());
    
    // 从参数中获取初始 index，默认为 0
    final initialIndex = Get.arguments as int? ?? 0;
    _currentIndex = initialIndex.clamp(0, 2);
    
    // 初始化对应的页面
    _initializePage(_currentIndex);
  }

  // 构建 NavigationRail
  List<NavigationRailDestination> _buildRailDestinations(
      ColorScheme colorScheme) {
    return _tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;

      // 如果是"我的"标签（index == 2），根据用户信息动态显示
      if (index == 2) {
        final userInfo = userInfoStore.userInfo.value;
        if (userInfo != null) {
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
      }
      return NavigationRailDestination(
        icon: Icon(tab.icon),
        selectedIcon: Icon(tab.activeIcon, color: colorScheme.primary),
        label: Text(tab.title),
      );
    }).toList();
  }

  // 构建 NavigationBar
  List<NavigationDestination> _buildBarDestinations(ColorScheme colorScheme) {
    return _tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      if (index == 2) {
        final userInfo = userInfoStore.userInfo.value;
        if (userInfo != null) {
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
      }

      // 默认显示或没有用户信息时
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
    // 使用 MediaQuery 获取宽度，判断是否为桌面端（宽屏）
    final bool isDesktop = MediaQuery.of(context).size.width >= 640;
    final colorScheme = Theme.of(context).colorScheme;
    mainPageState.changeIsDesktop(isDesktop);
    return WindowsTitleBar(
      child: Scaffold(
        body: Row(
        children: [
          if (isDesktop)
            Obx(() => NavigationRail(
                  backgroundColor: Colors.black12.withValues(alpha: 0.04),
                  selectedIndex: _currentIndex,
                  groupAlignment: 1.0,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  // 顶部搜索按钮
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                    child: FloatingActionButton(
                      heroTag: 'main_search',
                      elevation: 0,
                      onPressed: () {
                        Get.toNamed(RouteName.search);
                      },
                      child: const Icon(Icons.search),
                    ),
                  ),
                  // 底部设置按钮
                  trailing: Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 5),
                    child: IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        iconSize: 28,
                        tooltip: '设置',
                        onPressed: () => Navigator.of(context)
                            .pushNamed(RouteName.settings)),
                  ),
                  destinations: _buildRailDestinations(colorScheme),
                )),
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
          : Obx(() => NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onDestinationSelected,
                destinations: _buildBarDestinations(colorScheme),
              )),
      ),
    );
  }
}

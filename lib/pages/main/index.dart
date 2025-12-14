import 'package:anime_flow/controllers/main_page/main_page_state.dart';
import 'package:anime_flow/models/item/tab_item.dart';
import 'package:anime_flow/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/pages/Category/index.dart';
import 'package:anime_flow/pages/recommend/index.dart';
import 'package:anime_flow/pages/play/index.dart';
import 'package:get/get.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainPageState mainPageState;

  // 使用 GlobalKey 保持 IndexedStack 的状态，防止在布局切换（Row <-> Column）时页面重构
  final GlobalKey _bodyKey = GlobalKey();

  final List<TabItem> _tabs = [
    TabItem(
      type: TabType.home,
      title: "推荐",
      icon: Icons.home,
      activeIcon: Icons.home_filled,
    ),
    TabItem(
      type: TabType.category,
      title: "分类",
      icon: Icons.category_outlined,
      activeIcon: Icons.category,
    ),
    TabItem(
      type: TabType.profile,
      title: "视频",
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  // 懒加载页面缓存
  final List<Widget?> _pageCache = List.filled(3, null);

  @override
  void initState() {
    super.initState();
    mainPageState = Get.put(MainPageState());
    // 默认初始化第一个页面
    _pageCache[0] = const RecommendView();
    Util.initCrawlConfigs();
  }

  int _currentIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _currentIndex = index;
      if (_pageCache[index] == null) {
        switch (index) {
          case 0:
            _pageCache[index] = const RecommendView();
            break;
          case 1:
            _pageCache[index] = const CategoryView();
            break;
          case 2:
            _pageCache[index] = const PlayPage();
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用 MediaQuery 获取宽度，判断是否为桌面端（宽屏）
    final bool isDesktop = MediaQuery.of(context).size.width >= 640;
    final colorScheme = Theme.of(context).colorScheme;
    mainPageState.changeIsDesktop(isDesktop);
    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              backgroundColor: Colors.black12.withValues(alpha: 0.04),
              selectedIndex: _currentIndex,
              groupAlignment: 1.0,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              // 顶部搜索按钮
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: FloatingActionButton(
                  elevation: 0,
                  onPressed: () {
                    // TODO: 实现搜索功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('搜索功能开发中...')),
                    );
                  },
                  child: const Icon(Icons.search),
                ),
              ),
              // 底部设置按钮
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 16),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  iconSize: 28,
                  tooltip: '设置',
                  onPressed: () {
                    // TODO: 实现设置功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('设置功能开发中...')),
                    );
                  },
                ),
              ),
              destinations: _tabs.map((tab) {
                return NavigationRailDestination(
                  icon: Icon(tab.icon),
                  selectedIcon:
                      Icon(tab.activeIcon, color: colorScheme.primary),
                  label: Text(tab.title),
                );
              }).toList(),
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
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: _tabs.map((tab) {
                return NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon:
                      Icon(tab.activeIcon, color: colorScheme.primary),
                  label: tab.title,
                );
              }).toList(),
            ),
    );
  }
}

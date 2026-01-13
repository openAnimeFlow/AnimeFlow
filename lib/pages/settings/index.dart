import 'package:anime_flow/pages/settings/pages/danmaku_setting_page.dart';
import 'package:anime_flow/pages/settings/pages/data_source.dart';
import 'package:anime_flow/pages/settings/pages/theme.dart';
import 'package:anime_flow/pages/settings/setting_controller.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/pages/settings/pages/general_settings.dart';
import 'package:anime_flow/pages/settings/pages/playback_settings.dart';
import 'package:anime_flow/pages/settings/pages/about_settings.dart';
import 'package:get/get.dart';

///设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingController settingController;
  int _selectedIndex = 0;

  final List<_SettingsCategory> _categories = [
    _SettingsCategory(
      title: '应用与外观',
      items: [
        _SettingsMenuItem(
          title: '通用',
          icon: Icons.settings_outlined,
          route: RouteName.settingGeneral,
          page: const GeneralSettingsPage(),
        ),
        _SettingsMenuItem(
          title: '主题',
          icon: Icons.color_lens_outlined,
          route: RouteName.settingTheme,
          page: const ThemePage(),
        ),
      ],
    ),
    _SettingsCategory(
      title: '播放历史与视频源',
      items: [
        _SettingsMenuItem(
          title: '数据源管理',
          icon: Icons.smart_display_rounded,
          route: RouteName.settingDataSource,
          page: const DataSourcePage(),
        ),
      ],
    ),
    _SettingsCategory(
      title: '播放器设置',
      items: [
        _SettingsMenuItem(
          title: '播放',
          icon: Icons.play_circle_outline,
          route: RouteName.settingPlayback,
          page: const PlaybackSettingsPage(),
        ),
        _SettingsMenuItem(
          title: '弹幕设置',
          icon: Icons.subtitles_outlined,
          route: RouteName.settingDanmaku,
          page: const DanmakuSettingPage(),
        ),
      ],
    ),
    _SettingsCategory(
      title: '其他',
      items: [
        _SettingsMenuItem(
          title: '关于',
          icon: Icons.info_outline,
          route: RouteName.settingAbout,
          page: const AboutSettingsPage(),
        ),
      ],
    )
  ];

  List<_SettingsMenuItem> get _allMenuItems {
    return _categories.expand((category) => category.items).toList();
  }

  @override
  void initState() {
    super.initState();
    settingController = Get.put(SettingController());
  }

  @override
  void dispose() {
    Get.delete<SettingController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth > 600;
        settingController.setWideScreen(isWideScreen);
        if (isWideScreen) {
          // 宽屏布局：左侧菜单，右侧内容
          return Scaffold(
            body: Row(
              children: [
                // 左侧菜单
                Container(
                  width: 250,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top),
                        child: ListTile(
                            leading: const Icon(Icons.arrow_back),
                            title: const Text("设置"),
                            onTap: () => Get.back()),
                      ),
                      const Divider(height: 1),
                      // 菜单列表
                      Expanded(
                        child: ListView(
                            padding: EdgeInsets.only(
                                left: MediaQuery.of(context).padding.left +
                                    (Utils.isDesktop ? 15 : 0),
                                right: 15),
                            children: [
                              ..._categories.map((category) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 10),
                                      child: Text(
                                        category.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    ...category.items.map((item) {
                                      // 计算在所有菜单项中的全局索引
                                      final globalIndex =
                                          _allMenuItems.indexOf(item);
                                      final isSelected =
                                          globalIndex == _selectedIndex;
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedIndex = globalIndex;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 3, horizontal: 5),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(50),
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
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              }),
                            ]),
                      ),
                    ],
                  ),
                ),
                // 右侧内容
                Expanded(
                  child: _allMenuItems[_selectedIndex].page,
                ),
              ],
            ),
          );
        } else {
          // 手机布局：菜单列表，点击跳转路由
          return Scaffold(
            appBar: AppBar(
              title: const Text("设置"),
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _categories.map((category) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                          Navigator.of(context).pushNamed(item.route);
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
      },
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
  final String route;
  final Widget page;

  _SettingsMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.page,
  });
}

import 'package:anime_flow/pages/settings/pages/data_source.dart';
import 'package:anime_flow/pages/settings/setting_controller.dart';
import 'package:anime_flow/routes/index.dart';
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

  final List<_SettingsMenuItem> _menuItems = [
    _SettingsMenuItem(
      title: '通用',
      icon: Icons.settings_outlined,
      route: RouteName.settingsGeneral,
      page: const GeneralSettingsPage(),
    ),
    _SettingsMenuItem(
      title: '数据源管理',
      icon: Icons.smart_display_rounded,
      route: RouteName.settingsDataSource,
      page: const DataSourcePage(),
    ),
    _SettingsMenuItem(
      title: '播放',
      icon: Icons.play_circle_outline,
      route: RouteName.settingsPlayback,
      page: const PlaybackSettingsPage(),
    ),
    _SettingsMenuItem(
      title: '关于',
      icon: Icons.info_outline,
      route: RouteName.settingsAbout,
      page: const AboutSettingsPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    settingController = Get.put(SettingController());
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
                  width: 200,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    children: [
                      // 返回按钮
                      ListTile(
                        leading: const Icon(Icons.arrow_back),
                        title: const Text("返回"),
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const Divider(height: 1),
                      // 菜单列表
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: _menuItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isSelected = _selectedIndex == index;

                            return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.5)
                                          : null),
                                  child: Row(
                                    children: [
                                      Icon(item.icon),
                                      Text(item.title)
                                    ],
                                  ),
                                ));
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧内容
                Expanded(
                  child: _menuItems[_selectedIndex].page,
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
              children: _menuItems.map((item) {
                return ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed(item.route);
                  },
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }
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

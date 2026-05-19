import 'package:anime_flow/pages/settings/pages/danmaku_setting_page.dart';
import 'package:anime_flow/pages/settings/pages/plugins/plugins.dart';
import 'package:anime_flow/pages/settings/pages/theme.dart';
import 'package:anime_flow/pages/settings/setting_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anime_flow/pages/settings/pages/general_settings.dart';
import 'package:anime_flow/pages/settings/pages/playback_settings.dart';
import 'package:anime_flow/pages/settings/pages/about/index.dart';

///设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;
  bool? _syncedIsWideScreen;

  final List<_SettingsCategory> _categories = [
    _SettingsCategory(
      title: '应用与外观',
      items: [
        _SettingsMenuItem(
          title: '通用',
          icon: Icons.settings_outlined,
          route: const SettingGeneralRoute(),
          page: const GeneralSettingsPage(),
        ),
        _SettingsMenuItem(
          title: '主题样式',
          icon: Icons.color_lens_outlined,
          route: const SettingThemeRoute(),
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
          route: const SettingPluginsRoute(),
          page: const PluginsPage(),
        ),
      ],
    ),
    _SettingsCategory(
      title: '播放器设置',
      items: [
        _SettingsMenuItem(
          title: '播放',
          icon: Icons.play_circle_outline,
          route: const SettingPlaybackRoute(),
          page: const PlaybackSettingsPage(),
        ),
        _SettingsMenuItem(
          title: '弹幕设置',
          icon: Icons.subtitles_outlined,
          route: const SettingDanmakuRoute(),
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
          route: const SettingAboutRoute(),
          page: const AboutSettingsPage(),
        ),
      ],
    )
  ];

  List<_SettingsMenuItem> get _allMenuItems {
    return _categories.expand((category) => category.items).toList();
  }

  void _syncWideScreenIfNeeded(WidgetRef ref, bool isWideScreen) {
    if (_syncedIsWideScreen == isWideScreen) return;
    _syncedIsWideScreen = isWideScreen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(settingsLayoutProvider.notifier).setWideScreen(isWideScreen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWideScreen = constraints.maxWidth > 600;
            _syncWideScreenIfNeeded(ref, isWideScreen);
            return isWideScreen
                ? buildWideLayout(context)
                : buildNarrowLayout(context);
          },
        );
      },
    );
  }

  Widget buildWideLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.arrow_back),
                      title: const Text('设置'),
                      onTap: () => context.pop(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      left: MediaQuery.of(context).padding.left +
                          (SystemUtil.isDesktop ? 15 : 0),
                      right: 15,
                    ),
                    children: [
                      ..._categories.map((category) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 10,
                              ),
                              child: Text(
                                category.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            ...category.items.map((item) {
                              final globalIndex = _allMenuItems.indexOf(item);
                              final isSelected = globalIndex == _selectedIndex;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = globalIndex;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(50),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 3,
                                      horizontal: 3,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
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
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _allMenuItems[_selectedIndex].page,
          ),
        ],
      ),
    );
  }

  Widget buildNarrowLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _categories.map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    item.route.push(context);
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
  final GoRouteData route;
  final Widget page;

  _SettingsMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.page,
  });
}

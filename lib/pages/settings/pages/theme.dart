import 'dart:ui';

import 'package:anime_flow/providers/theme_provider.dart';
import 'package:anime_flow/pages/settings/setting_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/pages/settings/widget/setting_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  @override
  Widget build(BuildContext context) {
    final leftMediaQueryPadding = MediaQuery.of(context).padding.left;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer(
          builder: (context, ref, _) {
            final isWideScreen = ref.watch(settingsLayoutProvider);
            return AppBar(
              title: const Text('主题样式'),
              automaticallyImplyLeading: !isWideScreen,
              centerTitle: true,
            );
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: EdgeInsets.only(
                left: leftMediaQueryPadding + 16,
                right: 16,
                top: 16,
                bottom: 32),
            children: [
              const SettingTitle(title: '主题模式'),
              SettingCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Consumer(
                  builder: (context, ref, child) {
                    final themeState = ref.watch(themeProvider);
                    final themeNotifier = ref.read(themeProvider.notifier);

                    return SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            label: Text('跟随系统'),
                            icon: Icon(Icons.settings_suggest_outlined),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text('浅色模式'),
                            icon: Icon(Icons.wb_sunny_outlined),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text('深色模式'),
                            icon: Icon(Icons.nightlight_outlined),
                          ),
                        ],
                        selected: {themeState.themeMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          themeNotifier.setThemeMode(newSelection.first);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const SettingTitle(title: '主题颜色'),
              SettingCard(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Consumer(
                  builder: (context, ref, child) {
                    final themeState = ref.watch(themeProvider);
                    final themeNotifier = ref.read(themeProvider.notifier);
                    final selectedIndex =
                        ThemeNotifier.getColorIndex(themeState.seedColor);

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(5, (index) {
                            final themeColorData = ThemeNotifier.themeColors[index];
                            final color = themeColorData.color;
                            final isSelected = index == selectedIndex;
                            return _buildColorItem(context, themeNotifier, themeColorData, color, isSelected);
                          }),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(5, (index) {
                            final realIndex = index + 5;
                            final themeColorData = ThemeNotifier.themeColors[realIndex];
                            final color = themeColorData.color;
                            final isSelected = realIndex == selectedIndex;
                            return _buildColorItem(context, themeNotifier, themeColorData, color, isSelected);
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const SettingTitle(title: '外观设置'),
              SettingCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.font_download_outlined,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: const Text(
                    '字体样式',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('自定义应用字体'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => const SettingFontRoute().push(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorItem(BuildContext context, ThemeNotifier themeNotifier, themeColorData, Color color, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: () => themeNotifier.setSeedColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 28,
                      color: color.computeLuminance() > 0.55
                          ? Colors.black87
                          : Colors.white,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          themeColorData.name,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

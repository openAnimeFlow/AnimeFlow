import 'dart:ui';

import 'package:anime_flow/providers/theme_provider.dart';
import 'package:anime_flow/pages/settings/setting_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/theme/theme_preview.dart';
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
            );
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: EdgeInsets.only(
                left: leftMediaQueryPadding,
                right: 0,
                top: 16,
                bottom: 16),
            children: [
              const SettingTitle(title: '主题模式'),
              SettingCard(
                padding: const EdgeInsets.all(16),
                child: Consumer(
                  builder: (context, ref, child) {
                    final themeState = ref.watch(themeProvider);
                    final themeNotifier = ref.read(themeProvider.notifier);

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
                            child: ThemePreviewCard(
                              bg: const Color(0xFF020617),
                              primary: const Color(0xFF3B82F6),
                              titleColor: Colors.white,
                              subtitleColor: const Color(0xFF6B7280),
                              icon: Icons.nightlight_round,
                              title: "深色模式",
                              subtitle: "深色护眼",
                              selected:
                                  themeState.themeMode == ThemeMode.dark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                themeNotifier.setThemeMode(ThemeMode.light),
                            child: ThemePreviewCard(
                              bg: const Color(0xFFF8FAFC),
                              primary: const Color(0xFFFACC15),
                              titleColor: Colors.black,
                              subtitleColor: Colors.black54,
                              icon: Icons.wb_sunny,
                              title: "浅色模式",
                              subtitle: "明亮清爽",
                              selected:
                                  themeState.themeMode == ThemeMode.light,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                themeNotifier.setThemeMode(ThemeMode.system),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ThemePreviewCard(
                                bg: const Color(0xFF020617),
                                primary:
                                    Theme.of(context).colorScheme.primary,
                                titleColor: Colors.white,
                                subtitleColor: Colors.white60,
                                icon: Icons.settings,
                                title: "跟随系统",
                                subtitle: "自动适配",
                                overlay: const DiagonalOverlay(),
                                selected: themeState.themeMode ==
                                    ThemeMode.system,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SettingTitle(title: '主题颜色'),
              SettingCard(
                padding: const EdgeInsets.all(16),
                child: Consumer(
                  builder: (context, ref, child) {
                    final themeState = ref.watch(themeProvider);
                    final themeNotifier = ref.read(themeProvider.notifier);
                    final selectedIndex =
                        ThemeNotifier.getColorIndex(themeState.seedColor);

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: List.generate(ThemeNotifier.themeColors.length,
                          (index) {
                        final themeColorData = ThemeNotifier.themeColors[index];
                        final color = themeColorData.color;
                        final isSelected = index == selectedIndex;
                        return GestureDetector(
                          onTap: () => themeNotifier.setSeedColor(color),
                          child: SizedBox(
                            width: 56,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .outlineVariant
                                              .withValues(alpha: 0.5),
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 20,
                                          color: color.computeLuminance() > 0.55
                                              ? Colors.black87
                                              : Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  themeColorData.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              const SettingTitle(title: '字体样式'),
              SettingCard(
                child: ListTile(
                  leading: Icon(
                    Icons.text_fields_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    '字体样式',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('自定义应用字体'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => const SettingFontRoute().push(context),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget glassPanel(
      {required Widget child,
      EdgeInsetsGeometry? padding,
      BorderRadiusGeometry? borderRadius}) {
    borderRadius ??= BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: SystemUtil.isDarkTheme(context)
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            borderRadius: borderRadius,
            border: Border.all(
              color: SystemUtil.isDarkTheme(context)
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.15),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:anime_flow/providers/theme_provider.dart';
import 'package:anime_flow/controllers/setting_controller.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/theme/theme_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  late final SettingController settingController;

  @override
  void initState() {
    super.initState();
    settingController = Get.find<SettingController>();
  }

  @override
  Widget build(BuildContext context) {
    final leftMediaQueryPadding = MediaQuery.of(context).padding.left;

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题'),
        automaticallyImplyLeading: !settingController.isWideScreen.value,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: EdgeInsets.only(
                left: leftMediaQueryPadding == 0 ? 16 : leftMediaQueryPadding,
                right: 16),
            children: [
              const Text(
                '主题模式',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, child) {
                  final themeState = ref.watch(themeProvider);
                  final themeNotifier = ref.read(themeProvider.notifier);

                  return IntrinsicWidth(
                    child: glassPanel(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
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
                          const SizedBox(width: 5),
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
                          const SizedBox(width: 5),
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
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              const Text(
                '主题颜色',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, child) {
                  final themeState = ref.watch(themeProvider);
                  final themeNotifier = ref.read(themeProvider.notifier);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: LayoutUtil.getCrossAxisCount(context),
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: ThemeNotifier.themeColors.length,
                    itemBuilder: (context, index) {
                      final themeColorData =
                          ThemeNotifier.themeColors[index];
                      final color = themeColorData.color;
                      final isSelected = index ==
                          ThemeNotifier.getColorIndex(themeState.seedColor);
                      return GestureDetector(
                        onTap: () => themeNotifier.setSeedColor(color),
                        child: ThemeColorCard(
                          title: themeColorData.name,
                          background: color.withValues(alpha: 0.5),
                          header: color.withValues(alpha: 0.8),
                          text: Colors.white.withValues(alpha: 0.8),
                          button: color,
                          borderColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                      );
                    },
                  );
                },
              ),
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

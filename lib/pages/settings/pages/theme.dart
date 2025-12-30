import 'dart:ui';

import 'package:anime_flow/controllers/theme_controller.dart';
import 'package:anime_flow/pages/settings/setting_controller.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:anime_flow/widget/theme/theme_preview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  late SettingController settingController;
  late ThemeController themeController;

  @override
  void initState() {
    super.initState();
    settingController = Get.find<SettingController>();
    themeController = Get.find<ThemeController>();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = themeController.themeMode;

    return GetBuilder<ThemeController>(
      builder: (themeCtrl) => Scaffold(
        appBar: AppBar(
          title: const Text('主题'),
          automaticallyImplyLeading: !settingController.isWideScreen.value,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 主题模式选择
            const Text(
              '主题模式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GetBuilder<ThemeController>(
              builder: (controller) {
                return Center(
                  child: IntrinsicWidth(
                    child: glassPanel(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                controller.setThemeMode(ThemeMode.dark);
                              });
                            },
                            child: ThemePreviewCard(
                              bg: const Color(0xFF020617),
                              primary: const Color(0xFF3B82F6),
                              titleColor: Colors.white,
                              subtitleColor: const Color(0xFF6B7280),
                              icon: Icons.nightlight_round,
                              title: "深色模式",
                              subtitle: "深色护眼",
                              selected: themeMode == ThemeMode.dark,
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                controller.setThemeMode(ThemeMode.light);
                              });
                            },
                            child: ThemePreviewCard(
                              bg: const Color(0xFFF8FAFC),
                              primary: const Color(0xFFFACC15),
                              titleColor: Colors.black,
                              subtitleColor: Colors.black54,
                              icon: Icons.wb_sunny,
                              title: "浅色模式",
                              subtitle: "明亮清爽",
                              selected: themeMode == ThemeMode.light,
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                controller.setThemeMode(ThemeMode.system);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ThemePreviewCard(
                                bg: const Color(0xFF020617),
                                primary: Theme.of(context).colorScheme.primary,
                                titleColor: Colors.white,
                                subtitleColor: Colors.white60,
                                icon: Icons.settings,
                                title: "跟随系统",
                                subtitle: "自动适配",
                                overlay: const DiagonalOverlay(),
                                selected: themeMode == ThemeMode.system,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // 主题颜色选择
            const Text(
              '主题颜色',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 颜色网格
            GetBuilder<ThemeController>(
              builder: (controller) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: LayoutUtil.getCrossAxisCount(context) * 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: ThemeController.themeColors.length,
                  itemBuilder: (context, index) {
                    final color = ThemeController.themeColors[index];
                    final isSelected = index ==
                        ThemeController.getColorIndex(
                            themeController.seedColor);
                    return GestureDetector(
                      onTap: () {
                        themeController.setSeedColor(color);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: isSelected
                                ? controller.seedColor
                                : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget glassPanel(
      {required Widget child,
      EdgeInsetsGeometry? padding,
      BorderRadiusGeometry? borderRadius}) {
    final themeMode = themeController.themeMode;
    borderRadius ??= BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: themeMode == ThemeMode.dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            borderRadius: borderRadius,
            border: Border.all(
              color: themeMode == ThemeMode.dark
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

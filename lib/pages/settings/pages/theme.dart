import 'package:anime_flow/controllers/theme_controller.dart';
import 'package:anime_flow/pages/settings/setting_controller.dart';
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


  // 获取当前颜色索引
  int get _selectedColorIndex {
    final currentColor = themeController.seedColor;
    return ThemeController.themeColors.indexWhere(
      (color) => color.toARGB32() == currentColor.toARGB32(),
    );
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
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          controller.setThemeMode(ThemeMode.dark);
                        });
                      },
                      child: Column(
                        children: [
                          ThemePreviewCard(
                            borderWidth: 5,
                            borderColor: themeMode == ThemeMode.dark
                                ? controller.seedColor
                                : Colors.black45,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            background: const Color(0xFF121212),
                            header: Colors.blueGrey,
                            text: Colors.white70,
                            button: Colors.tealAccent,
                          ),
                          const Text(
                            '深色',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          controller.setThemeMode(ThemeMode.light);
                        });
                      },
                      child: Column(
                        children: [
                          ThemePreviewCard(
                            borderColor: themeMode == ThemeMode.light
                                ? controller.seedColor
                                : Colors.black45,
                            borderWidth: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            background: Colors.white,
                            header: Colors.blue.shade200,
                            text: Colors.black87,
                            button: Colors.blue,
                          ),
                          const Text(
                            '浅色',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          controller.setThemeMode(ThemeMode.system);
                        });
                      },
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              // 底层：深色
                              ThemePreviewCard(
                                borderWidth: 5,
                                borderColor: themeMode == ThemeMode.system
                                    ? controller.seedColor
                                    : Colors.black45,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                background: const Color(0xFF121212),
                                header: Colors.blueGrey,
                                text: Colors.white70,
                                button: Colors.tealAccent,
                              ),

                              // 上层：浅色 + 对角裁剪
                              ClipPath(
                                clipper: DiagonalClipper(),
                                child: ThemePreviewCard(
                                  borderWidth: 5,
                                  borderColor: themeMode == ThemeMode.system
                                      ? controller.seedColor
                                      : Colors.black45,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  background: Colors.white,
                                  header: Colors.blue.shade200,
                                  text: Colors.black87,
                                  button: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            '跟随系统',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: ThemeController.themeColors.length,
                  itemBuilder: (context, index) {
                    final color = ThemeController.themeColors[index];
                    final isSelected = index == _selectedColorIndex;
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
}

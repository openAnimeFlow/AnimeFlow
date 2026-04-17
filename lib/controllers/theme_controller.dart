import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = themeColors[0].color;

  static const String _themeModeKey = 'themeMode';
  static const String _seedColorKey = 'seedColor';

  ThemeMode get themeMode => _themeMode;

  Color get seedColor => _seedColor;

  // 预定义主题颜色
  static final List<ThemeColorData> themeColors = [
    const ThemeColorData(
      color: Color(0xFF5CDCF6),
      name: '青色',
    ),
    const ThemeColorData(
      color: Colors.green,
      name: '绿色',
    ),
    const ThemeColorData(
      color: Colors.teal,
      name: '青绿色',
    ),
    const ThemeColorData(
      color: Colors.blue,
      name: '蓝色',
    ),
    const ThemeColorData(
      color: Colors.indigo,
      name: '靛蓝色',
    ),
    const ThemeColorData(
      color: Color(0xff6750a4),
      name: '紫罗兰色',
    ),
    const ThemeColorData(
      color: Colors.pink,
      name: '粉色',
    ),
    const ThemeColorData(
      color: Colors.yellow,
      name: '黄色',
    ),
    const ThemeColorData(
      color: Colors.orange,
      name: '橙色',
    ),
    const ThemeColorData(
      color: Colors.deepOrange,
      name: '深橙色',
    ),
  ];

  // 获取颜色在列表中的索引
  static int getColorIndex(Color color) {
    return themeColors.indexWhere(
      (c) => c.color.toARGB32() == color.toARGB32(),
    );
  }

  // 初始化主题设置
  Future<void> initTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // 读取主题模式
    final themeModeIndex = prefs.getInt(_themeModeKey);
    if (themeModeIndex != null && themeModeIndex >= 0 && themeModeIndex <= 2) {
      _themeMode = ThemeMode.values[themeModeIndex];
    } else {
      _themeMode = ThemeMode.system;
    }

    // 读取主题颜色
    final seedColorValue = prefs.getInt(_seedColorKey);
    if (seedColorValue != null) {
      _seedColor = Color(seedColorValue);
    } else {
      _seedColor = themeColors[0].color;
    }

    update();
  }

  // 设置主题模式并保存
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    update();
  }

  // 设置主题颜色并保存
  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.toARGB32());
    update();
  }

  // 获取浅色主题
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
    );
  }

  // 获取深色主题
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
    );
  }
}

class ThemeColorData {
  final Color color;
  final String name;

  const ThemeColorData({
    required this.color,
    required this.name,
  });
}
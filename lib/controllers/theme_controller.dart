import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = themeColors[0];

  static const String _themeModeKey = 'themeMode';
  static const String _seedColorKey = 'seedColor';

  ThemeMode get themeMode => _themeMode;

  Color get seedColor => _seedColor;

  // 预定义主题颜色
  static final List<Color> themeColors = [
    const Color(0xFF5CDCF6),
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.indigo,
    const Color(0xff6750a4),
    Colors.pink,
    Colors.yellow,
    Colors.orange,
    Colors.deepOrange,
  ];

  // 获取颜色在列表中的索引
  static int getColorIndex(Color color) {
    return themeColors.indexWhere(
      (c) => c.toARGB32() == color.toARGB32(),
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
      _seedColor = themeColors[0];
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

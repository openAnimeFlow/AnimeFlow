import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

/// 预置主题色（与持久化 seed 对应）
class ThemeColorData {
  final Color color;
  final String name;

  const ThemeColorData({
    required this.color,
    required this.name,
  });
}

/// 预定义主题颜色列表
final List<ThemeColorData> themeColorPresets = [
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

int themeColorPresetIndex(Color color) {
  return themeColorPresets.indexWhere(
    (c) => c.color.toARGB32() == color.toARGB32(),
  );
}

/// 当前主题模式与种子色（Riverpod 状态）
@immutable
class ThemeState {
  final ThemeMode themeMode;
  final Color seedColor;

  const ThemeState({
    required this.themeMode,
    required this.seedColor,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}

ThemeData buildLightTheme(Color seedColor) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
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

ThemeData buildDarkTheme(Color seedColor) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
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

/// 全局主题（保持存活，避免未监听时被 dispose）。
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  static const String _themeModeKey = 'themeMode';
  static const String _seedColorKey = 'seedColor';

  @override
  ThemeState build() {
    return ThemeState(
      themeMode: ThemeMode.system,
      seedColor: themeColorPresets.first.color,
    );
  }

  /// 从 SharedPreferences 恢复（在 [main] 中于 [runApp] 前调用）
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    ThemeMode mode = ThemeMode.system;
    final themeModeIndex = prefs.getInt(_themeModeKey);
    if (themeModeIndex != null &&
        themeModeIndex >= 0 &&
        themeModeIndex < ThemeMode.values.length) {
      mode = ThemeMode.values[themeModeIndex];
    }

    Color seed = themeColorPresets.first.color;
    final seedColorValue = prefs.getInt(_seedColorKey);
    if (seedColorValue != null) {
      seed = Color(seedColorValue);
    }

    state = ThemeState(themeMode: mode, seedColor: seed);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.toARGB32());
  }
}

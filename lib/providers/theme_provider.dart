import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

class ThemeState {
  const ThemeState({
    required this.themeMode,
    required this.seedColor,
    this.fontFamily,
  });

  final ThemeMode themeMode;
  final Color seedColor;
  final String? fontFamily;

  static const _undefinedFontFamily = Object();

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    Object? fontFamily = _undefinedFontFamily,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      fontFamily: identical(fontFamily, _undefinedFontFamily)
          ? this.fontFamily
          : fontFamily as String?,
    );
  }
}

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
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

  @override
  ThemeState build() {
    return _loadThemeFromStorage();
  }

  ThemeState _loadThemeFromStorage() {
    final setting = Storage.setting;

    ThemeMode themeMode = ThemeMode.system;
    final themeModeIndex =
        setting.get(SettingKey.themeMode, defaultValue: ThemeMode.system.index);
    if (themeModeIndex is int &&
        themeModeIndex >= 0 &&
        themeModeIndex <= 2) {
      themeMode = ThemeMode.values[themeModeIndex];
    }

    Color seedColor = themeColors[0].color;
    final seedColorValue = setting.get(SettingKey.seedColor);
    if (seedColorValue is int) {
      seedColor = Color(seedColorValue);
    }

    final fontFamily = setting.get(SettingKey.fontFamily) as String?;

    return ThemeState(
      themeMode: themeMode,
      seedColor: seedColor,
      fontFamily: fontFamily,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    Storage.setting.put(SettingKey.themeMode, mode.index);
  }

  void setSeedColor(Color color) {
    state = state.copyWith(seedColor: color);
    Storage.setting.put(SettingKey.seedColor, color.toARGB32());
  }

  void setFontFamily(String? family) {
    state = state.copyWith(fontFamily: family);
  }
}

ThemeData buildLightTheme(Color seedColor, {String? fontFamily}) {
  return ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
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

ThemeData buildDarkTheme(Color seedColor, {String? fontFamily}) {
  return ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
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

class ThemeColorData {
  final Color color;
  final String name;

  const ThemeColorData({
    required this.color,
    required this.name,
  });
}

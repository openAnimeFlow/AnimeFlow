import 'package:anime_flow/pages/main/index.dart';
import 'package:anime_flow/pages/calendar/index.dart';
import 'package:anime_flow/pages/my/index.dart';
import 'package:anime_flow/pages/play/index.dart';
import 'package:anime_flow/pages/search/index.dart';
import 'package:anime_flow/pages/anime_info/index.dart';
import 'package:anime_flow/pages/settings/index.dart';
import 'package:anime_flow/pages/settings/pages/about/about_settings.dart';
import 'package:anime_flow/pages/settings/pages/about/thanks.dart';
import 'package:anime_flow/pages/settings/pages/danmaku_setting_page.dart';
import 'package:anime_flow/pages/settings/pages/general_settings.dart';
import 'package:anime_flow/pages/settings/pages/playback_settings.dart';
import 'package:anime_flow/pages/settings/pages/plugins/add_plugins.dart';
import 'package:anime_flow/pages/settings/pages/plugins/download_plugins.dart';
import 'package:anime_flow/pages/settings/pages/plugins/plugins.dart';
import 'package:anime_flow/pages/settings/pages/theme.dart';
import 'package:flutter/material.dart';

class RouteName {
  static const String main = "/";
  static const String login = "/login";
  static const String animeInfo = "/anime_info";
  static const String play = "/play";
  static const String search = "/search";
  static const String calendar = "/calendar";
  
  // 设置页面路由
  static const String settings = "/settings";
  static const String settingGeneral = "/settings/general";
  static const String settingPlayback = "/settings/playback";
  static const String settingAbout = "/settings/about";
  static const String settingPlugins = "/settings/Plugins";
  static const String settingAddPlugins = "/settings/addPlugins";
  static const String settingTheme = "/settings/theme";
  static const String settingDanmaku = "/settings/danmaku";
  static const String settingDownloadPlugins = "/settings/downloadPlugins";
  static const String settingThanks = "/settings/thanks";
}

Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {
    RouteName.main: (context) => const MainPage(),
    RouteName.login: (context) => const MyPage(),
    RouteName.animeInfo: (context) => const AnimeDetailPage(),
    RouteName.play: (context) => const PlayPage(),
    RouteName.search: (context) => const SearchPage(),
    RouteName.calendar: (context) => const CalendarPage(),
    ...settingsRoutes(),
  };
}


/// 设置页面路由
Map<String, Widget Function(BuildContext)> settingsRoutes() {
  return {
    RouteName.settings: (context) => const SettingsPage(),
    RouteName.settingGeneral: (context) => const GeneralSettingsPage(),
    RouteName.settingPlayback: (context) => const PlaybackSettingsPage(),
    RouteName.settingDownloadPlugins: (context) => const DownloadPluginsPage(),
    RouteName.settingDanmaku: (context) => const DanmakuSettingPage(),
    RouteName.settingAbout: (context) => const AboutSettingsPage(),
    RouteName.settingPlugins: (context) => const PluginsPage(),
    RouteName.settingAddPlugins: (context) => const AddPluginsPage(),
    RouteName.settingTheme: (context) => const ThemePage(),
    RouteName.settingThanks: (context) => const ThanksPage(),
  };
}

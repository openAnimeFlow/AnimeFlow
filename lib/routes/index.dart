import 'package:anime_flow/pages/main/index.dart';
import 'package:anime_flow/pages/calendar/index.dart';
import 'package:anime_flow/pages/my/index.dart';
import 'package:anime_flow/pages/play/index.dart';
import 'package:anime_flow/pages/search/index.dart';
import 'package:anime_flow/pages/settings/index.dart';
import 'package:anime_flow/pages/settings/pages/add_source.dart';
import 'package:anime_flow/pages/settings/pages/data_source.dart';
import 'package:anime_flow/pages/settings/pages/general_settings.dart';
import 'package:anime_flow/pages/settings/pages/playback_settings.dart';
import 'package:anime_flow/pages/settings/pages/about_settings.dart';
import 'package:anime_flow/pages/settings/pages/theme.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/pages/anime_info/index.dart';

class RouteName {
  static const String main = "/";
  static const String login = "/login";
  static const String animeInfo = "/anime_info";
  static const String play = "/play";
  static const String search = "/search";
  static const String calendar = "/calendar";
  static const String settings = "/settings";
  static const String settingsGeneral = "/settings/general";
  static const String settingsPlayback = "/settings/playback";
  static const String settingsAbout = "/settings/about";
  static const String settingsDataSource = "/settings/dataSource";
  static const String settingAddSource = "/settings/addSource";
  static const String settingsTheme = "/settings/theme";
}

Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {
    RouteName.main: (context) => const MainPage(),
    RouteName.login: (context) => const MyPage(),
    RouteName.animeInfo: (context) => const AnimeDetailPage(),
    RouteName.play: (context) => const PlayPage(),
    RouteName.search: (context) => const SearchPage(),
    RouteName.calendar: (context) => const CalendarPage(),
    RouteName.settings: (context) => const SettingsPage(),
    RouteName.settingsGeneral: (context) => const GeneralSettingsPage(),
    RouteName.settingsPlayback: (context) => const PlaybackSettingsPage(),
    RouteName.settingsAbout: (context) => const AboutSettingsPage(),
    RouteName.settingsDataSource: (context) => const DataSourcePage(),
    RouteName.settingAddSource: (context) => const AddSourcePage(),
    RouteName.settingsTheme: (context) => const ThemePage(),
  };
}

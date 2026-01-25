import 'package:anime_flow/pages/main/index.dart';
import 'package:anime_flow/pages/calendar/index.dart';
import 'package:anime_flow/pages/my/index.dart';
import 'package:anime_flow/pages/play/index.dart';
import 'package:anime_flow/pages/search/index.dart';
import 'package:anime_flow/pages/anime_info/index.dart';
import 'package:anime_flow/pages/settings/index.dart';
import 'package:anime_flow/pages/settings/pages/about/index.dart';
import 'package:anime_flow/pages/settings/pages/about/thanks.dart';
import 'package:anime_flow/pages/settings/pages/agreement/index.dart';
import 'package:anime_flow/pages/settings/pages/danmaku_setting_page.dart';
import 'package:anime_flow/pages/settings/pages/general_settings.dart';
import 'package:anime_flow/pages/settings/pages/playback_settings.dart';
import 'package:anime_flow/pages/settings/pages/plugins/add_plugins.dart';
import 'package:anime_flow/pages/settings/pages/plugins/download_plugins.dart';
import 'package:anime_flow/pages/settings/pages/plugins/plugins.dart';
import 'package:anime_flow/pages/settings/pages/theme.dart';
import 'package:get/get.dart';

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
  static const String settingAgreement = "/settings/agreement";
}

List<GetPage> getPages() {
  return [
    GetPage(
      name: RouteName.main,
      page: () => const MainPage(),
    ),
    GetPage(
      name: RouteName.login,
      page: () => const MyPage(),
    ),
    GetPage(
      name: RouteName.animeInfo,
      page: () => const AnimeInfoPage(),
    ),
    GetPage(
      name: RouteName.play,
      page: () => const PlayPage(),
    ),
    GetPage(
      name: RouteName.search,
      page: () => const SearchPage(),
    ),
    GetPage(
      name: RouteName.calendar,
      page: () => const CalendarPage(),
    ),
    ...settingsPages(),
  ];
}

/// 设置页面路由
List<GetPage> settingsPages() {
  return [
    GetPage(
      name: RouteName.settings,
      page: () => const SettingsPage(),
    ),
    GetPage(
      name: RouteName.settingGeneral,
      page: () => const GeneralSettingsPage(),
    ),
    GetPage(
      name: RouteName.settingPlayback,
      page: () => const PlaybackSettingsPage(),
    ),
    GetPage(
      name: RouteName.settingDownloadPlugins,
      page: () => const DownloadPluginsPage(),
    ),
    GetPage(
      name: RouteName.settingDanmaku,
      page: () => const DanmakuSettingPage(),
    ),
    GetPage(
      name: RouteName.settingAbout,
      page: () => const AboutSettingsPage(),
    ),
    GetPage(
      name: RouteName.settingPlugins,
      page: () => const PluginsPage(),
    ),
    GetPage(
      name: RouteName.settingAddPlugins,
      page: () => const AddPluginsPage(),
    ),
    GetPage(
      name: RouteName.settingTheme,
      page: () => const ThemePage(),
    ),
    GetPage(
      name: RouteName.settingThanks,
      page: () => const ThanksPage(),
    ),
    GetPage(
      name: RouteName.settingAgreement,
      page: () => const AgreementPage(),
    ),
  ];
}

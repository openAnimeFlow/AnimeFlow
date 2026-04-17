import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/pages/anime_info/index.dart';
import 'package:anime_flow/pages/calendar/index.dart';
import 'package:anime_flow/pages/character_info/index.dart';
import 'package:anime_flow/pages/characters/index.dart';
import 'package:anime_flow/pages/main/index.dart';
import 'package:anime_flow/pages/my/index.dart';
import 'package:anime_flow/pages/my/play_record/index.dart';
import 'package:anime_flow/pages/play/index.dart';
import 'package:anime_flow/pages/search/index.dart';
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
import 'package:anime_flow/pages/user_space/index.dart';
import 'package:anime_flow/controllers/my_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';


class RouteName {
  static const String main = "/";
  static const String login = "/login";
  static const String animeInfo = "/anime_info";
  static const String play = "/play";
  static const String search = "/search";
  static const String calendar = "/calendar";
  static const String characters = "/characters";
  static const String characterInfo = "/character_info";
  static const String playRecord = "/play_record";
  static const String userSpace = "/user_space";

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

/// 播放页路由参数
class PlayRouteExtra {
  final SubjectBasicData subjectBasicData;
  final int? continueEpisode;

  const PlayRouteExtra({
    required this.subjectBasicData,
    this.continueEpisode,
  });
}

/// 动漫详情页路由参数
class AnimeInfoExtra {
  final int id;
  final String name;
  final String image;

  AnimeInfoExtra(
      {required this.id, required this.name, required this.image});
}

/// 角色详情页路由参数
class CharacterInfoExtra {
  final int characterId;
  final String characterName;
  final String characterImage;

  const CharacterInfoExtra({
    required this.characterId,
    required this.characterName,
    required this.characterImage,
  });
}

Widget _invalidArgs([String message = '路由参数无效']) {
  return Scaffold(
    body: Center(child: Text(message)),
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: Get.key,
  initialLocation: RouteName.main,
  redirect: (context, state) {
    final uri = state.uri;
    if (MyController.isOAuthAppCallback(uri)) {
      final link = uri.toString();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        MyController.handleDeepLink(link).catchError(
              (Object e, StackTrace st) =>
              Logger().e('OAuth 回调处理失败', error: e, stackTrace: st),
        );
      });
      return RouteName.main;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: RouteName.main,
      builder: (context, state) {
        final tab = state.extra is int ? state.extra as int : 0;
        return MainPage(initialTabIndex: tab);
      },
    ),
    GoRoute(
      path: RouteName.login,
      builder: (context, state) => const MyPage(),
    ),
    GoRoute(
      path: RouteName.animeInfo,
      builder: (context, state) {
        final data = state.extra;
        if (data is! SubjectBasicData) return _invalidArgs();
        return AnimeInfoPage(animeInfoExtra: data);
      },
    ),
    GoRoute(
      path: RouteName.play,
      builder: (context, state) {
        final data = state.extra;
        if (data is! PlayRouteExtra) return _invalidArgs();
        return PlayPage(extra: data);
      },
    ),
    GoRoute(
      path: RouteName.search,
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: RouteName.calendar,
      builder: (context, state) {
        final data = state.extra;
        if (data is! Calendar) return _invalidArgs();
        return CalendarPage(calendar: data);
      },
    ),
    GoRoute(
      path: RouteName.characters,
      builder: (context, state) {
        final id = state.extra;
        if (id is! int) return _invalidArgs();
        return CharacterPage(subjectsId: id);
      },
    ),
    GoRoute(
      path: RouteName.characterInfo,
      builder: (context, state) {
        final data = state.extra;
        if (data is! CharacterInfoExtra) return _invalidArgs();
        return CharacterInfo(extra: data);
      },
    ),
    GoRoute(
      path: RouteName.playRecord,
      builder: (context, state) => const PlayRecordPage(),
    ),
    GoRoute(
      path: RouteName.userSpace,
      builder: (context, state) {
        final name = state.extra;
        if (name is! String) return _invalidArgs();
        return UserSpacePage(username: name);
      },
    ),
    GoRoute(
      path: RouteName.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: RouteName.settingGeneral,
      builder: (context, state) => const GeneralSettingsPage(),
    ),
    GoRoute(
      path: RouteName.settingPlayback,
      builder: (context, state) => const PlaybackSettingsPage(),
    ),
    GoRoute(
      path: RouteName.settingDownloadPlugins,
      builder: (context, state) => const DownloadPluginsPage(),
    ),
    GoRoute(
      path: RouteName.settingDanmaku,
      builder: (context, state) => const DanmakuSettingPage(),
    ),
    GoRoute(
      path: RouteName.settingAbout,
      builder: (context, state) => const AboutSettingsPage(),
    ),
    GoRoute(
      path: RouteName.settingPlugins,
      builder: (context, state) => const PluginsPage(),
    ),
    GoRoute(
      path: RouteName.settingAddPlugins,
      builder: (context, state) => AddPluginsPage(
        editPluginKey: state.extra is String ? state.extra as String : null,
      ),
    ),
    GoRoute(
      path: RouteName.settingTheme,
      builder: (context, state) => const ThemePage(),
    ),
    GoRoute(
      path: RouteName.settingThanks,
      builder: (context, state) => const ThanksPage(),
    ),
    GoRoute(
      path: RouteName.settingAgreement,
      builder: (context, state) => const AgreementPage(),
    ),
  ],
);

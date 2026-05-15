import 'package:anime_flow/controllers/my_controller.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/pages/anime_info/index.dart';
import 'package:anime_flow/pages/calendar/index.dart';
import 'package:anime_flow/pages/character_info/index.dart';
import 'package:anime_flow/pages/characters/index.dart';
import 'package:anime_flow/pages/main/index.dart';
import 'package:anime_flow/pages/my/index.dart';
import 'package:anime_flow/pages/oauth/oauth_callback_page.dart';
import 'package:anime_flow/pages/my/play_record/index.dart';
import 'package:anime_flow/pages/play/index.dart';
import 'package:anime_flow/pages/search/image_search_page.dart';
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

part 'routes.g.dart';


// =====================================================================
// 页面构造时仍在使用的复合参数对象（非路由数据本身）。
// =====================================================================

/// 播放页传给 [PlayPage] 的参数集。
class PlayRouteExtra {
  final SubjectBasicData subjectBasicData;
  final int? continueEpisode;

  const PlayRouteExtra({
    required this.subjectBasicData,
    this.continueEpisode,
  });
}

/// 角色详情页传给 [CharacterInfo] 的参数集。
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

// =====================================================================
// 路由定义（go_router_builder typed routes）。
// 关键参数走 query parameters，确保 Hot Restart / Inspector / 深链接
// 重建时能够从 URL 完全还原；复杂对象则使用 $extra。
// =====================================================================

@TypedGoRoute<MainRoute>(path: '/')
class MainRoute extends GoRouteData with $MainRoute {
  const MainRoute({this.tab = 0});
  final int tab;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return MainPage(initialTabIndex: tab);
  }
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MyPage();
}

@TypedGoRoute<OauthCallbackRoute>(path: '/oauth/callback')
class OauthCallbackRoute extends GoRouteData with $OauthCallbackRoute {
  const OauthCallbackRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      OAuthCallbackPage(callbackUri: state.uri);
}

@TypedGoRoute<AnimeInfoRoute>(path: '/anime_info')
class AnimeInfoRoute extends GoRouteData with $AnimeInfoRoute {
  const AnimeInfoRoute({
    required this.id,
    required this.name,
    required this.image,
  });

  factory AnimeInfoRoute.fromData(SubjectBasicData data) => AnimeInfoRoute(
        id: data.id,
        name: data.name,
        image: data.image,
      );

  final int id;
  final String name;
  final String image;

  @override
  Widget build(BuildContext context, GoRouterState state) => AnimeInfoPage(
        animeInfoExtra: SubjectBasicData(id: id, name: name, image: image),
      );
}

@TypedGoRoute<PlayRoute>(path: '/play')
class PlayRoute extends GoRouteData with $PlayRoute {
  const PlayRoute({
    required this.id,
    required this.name,
    required this.image,
    this.continueEpisode,
  });

  factory PlayRoute.fromData(
    SubjectBasicData data, {
    int? continueEpisode,
  }) =>
      PlayRoute(
        id: data.id,
        name: data.name,
        image: data.image,
        continueEpisode: continueEpisode,
      );

  final int id;
  final String name;
  final String image;
  final int? continueEpisode;

  @override
  Widget build(BuildContext context, GoRouterState state) => PlayPage(
        extra: PlayRouteExtra(
          subjectBasicData: SubjectBasicData(id: id, name: name, image: image),
          continueEpisode: continueEpisode,
        ),
      );
}

@TypedGoRoute<SearchRoute>(path: '/search')
class SearchRoute extends GoRouteData with $SearchRoute {
  const SearchRoute({this.keywords});

  final String? keywords;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SearchPage(keywords: keywords);
}

@TypedGoRoute<CalendarRoute>(path: '/calendar')
class CalendarRoute extends GoRouteData with $CalendarRoute {
  const CalendarRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CalendarPage();
}

@TypedGoRoute<CharactersRoute>(path: '/characters')
class CharactersRoute extends GoRouteData with $CharactersRoute {
  const CharactersRoute({required this.subjectsId});

  final int subjectsId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CharacterPage(subjectsId: subjectsId);
}

@TypedGoRoute<CharacterInfoRoute>(path: '/character_info')
class CharacterInfoRoute extends GoRouteData with $CharacterInfoRoute {
  const CharacterInfoRoute({
    required this.id,
    required this.name,
    required this.image,
  });

  factory CharacterInfoRoute.fromExtra(CharacterInfoExtra extra) =>
      CharacterInfoRoute(
        id: extra.characterId,
        name: extra.characterName,
        image: extra.characterImage,
      );

  final int id;
  final String name;
  final String image;

  @override
  Widget build(BuildContext context, GoRouterState state) => CharacterInfo(
        extra: CharacterInfoExtra(
          characterId: id,
          characterName: name,
          characterImage: image,
        ),
      );
}

@TypedGoRoute<PlayRecordRoute>(path: '/play_record')
class PlayRecordRoute extends GoRouteData with $PlayRecordRoute {
  const PlayRecordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PlayRecordPage();
}

@TypedGoRoute<UserSpaceRoute>(path: '/user_space')
class UserSpaceRoute extends GoRouteData with $UserSpaceRoute {
  const UserSpaceRoute({required this.name});

  final String name;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      UserSpacePage(username: name);
}

@TypedGoRoute<ImageSearchRoute>(path: '/image_search')
class ImageSearchRoute extends GoRouteData with $ImageSearchRoute {
  const ImageSearchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ImageSearchPage();
}

@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsPage();
}

@TypedGoRoute<SettingGeneralRoute>(path: '/settings/general')
class SettingGeneralRoute extends GoRouteData with $SettingGeneralRoute {
  const SettingGeneralRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const GeneralSettingsPage();
}

@TypedGoRoute<SettingPlaybackRoute>(path: '/settings/playback')
class SettingPlaybackRoute extends GoRouteData with $SettingPlaybackRoute {
  const SettingPlaybackRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PlaybackSettingsPage();
}

@TypedGoRoute<SettingDownloadPluginsRoute>(path: '/settings/downloadPlugins')
class SettingDownloadPluginsRoute extends GoRouteData
    with $SettingDownloadPluginsRoute {
  const SettingDownloadPluginsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DownloadPluginsPage();
}

@TypedGoRoute<SettingDanmakuRoute>(path: '/settings/danmaku')
class SettingDanmakuRoute extends GoRouteData with $SettingDanmakuRoute {
  const SettingDanmakuRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DanmakuSettingPage();
}

@TypedGoRoute<SettingAboutRoute>(path: '/settings/about')
class SettingAboutRoute extends GoRouteData with $SettingAboutRoute {
  const SettingAboutRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AboutSettingsPage();
}

@TypedGoRoute<SettingPluginsRoute>(path: '/settings/Plugins')
class SettingPluginsRoute extends GoRouteData with $SettingPluginsRoute {
  const SettingPluginsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PluginsPage();
}

@TypedGoRoute<SettingAddPluginsRoute>(path: '/settings/addPlugins')
class SettingAddPluginsRoute extends GoRouteData with $SettingAddPluginsRoute {
  const SettingAddPluginsRoute({this.editPluginKey});

  final String? editPluginKey;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AddPluginsPage(editPluginKey: editPluginKey);
}

@TypedGoRoute<SettingThemeRoute>(path: '/settings/theme')
class SettingThemeRoute extends GoRouteData with $SettingThemeRoute {
  const SettingThemeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ThemePage();
}

@TypedGoRoute<SettingThanksRoute>(path: '/settings/thanks')
class SettingThanksRoute extends GoRouteData with $SettingThanksRoute {
  const SettingThanksRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ThanksPage();
}

@TypedGoRoute<SettingAgreementRoute>(path: '/settings/agreement')
class SettingAgreementRoute extends GoRouteData with $SettingAgreementRoute {
  const SettingAgreementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AgreementPage();
}

// =====================================================================
// GoRouter 实例
// =====================================================================

final GoRouter appRouter = GoRouter(
  navigatorKey: Get.key,
  initialLocation: const MainRoute().location,
  redirect: (context, state) {
    final uri = state.uri;
    if (MyController.isOAuthAppCallbackUri(uri)) {
      final q = uri.hasQuery ? '?${uri.query}' : '';
      return '/oauth/callback$q';
    }
    return null;
  },
  routes: $appRoutes,
);

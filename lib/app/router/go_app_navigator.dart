import 'package:anime_flow/shared/navigation/app_navigator.dart';
import 'package:anime_flow/shared/navigation/args/image_viewer_extra.dart';
import 'package:anime_flow/shared/navigation/args/wallpaper_detail_args.dart';
import 'package:anime_flow/shared/navigation/args/info_route_extra.dart';
import 'package:anime_flow/shared/navigation/args/character_info_extra.dart';
import 'package:anime_flow/shared/navigation/args/play_route_extra.dart';
import 'package:anime_flow/shared/navigation/settings_destination.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';

import 'app_router.dart';

/// 将导航请求转换为生成的类型安全路由调用。
///
/// 使用调用方的上下文，保持嵌套导航器的现有行为。
class GoAppNavigator implements AppNavigator {
  const GoAppNavigator();

  @override
  Future<T?> openRegister<T>(BuildContext context) =>
      const RegisterRoute().push<T>(context);

  @override
  Future<T?> openForgotPassword<T>(BuildContext context) =>
      const ForgotPasswordRoute().push<T>(context);

  @override
  void goToUser(BuildContext context) => const UserRoute().go(context);

  @override
  Future<T?> openWallpaper<T>(BuildContext context, WallpaperDetailArgs args) =>
      WallpaperDetailRoute($extra: args).push<T>(context);

  @override
  Future<T?> openImagePreview<T>(
          BuildContext context, ImageViewerRouteArgs args) =>
      ImagePreviewRoute.fromArgs(args).push<T>(context);

  @override
  Future<T?> openAnimeInfo<T>(
    BuildContext context, {
    required int id,
    required String name,
    required String image,
    InfoRouteExtra? extra,
  }) =>
      AnimeInfoRoute(id: id, name: name, image: image, $extra: extra)
          .push<T>(context);

  @override
  Future<T?> openAnimeInfoFromExtra<T>(
          BuildContext context, InfoRouteExtra extra) =>
      AnimeInfoRoute.fromExtra(extra).push<T>(context);

  @override
  Future<T?> openPlay<T>(BuildContext context, PlayRouteExtra args) =>
      PlayRoute.fromExtra(args).push<T>(context);

  @override
  Future<T?> openCharacters<T>(BuildContext context,
          {required int subjectsId}) =>
      CharactersRoute(subjectsId: subjectsId).push<T>(context);

  @override
  Future<T?> openCharacterInfo<T>(
    BuildContext context, {
    required int id,
    required String name,
    required String image,
    CharacterInfoExtra? extra,
  }) =>
      CharacterInfoRoute(id: id, name: name, image: image, $extra: extra)
          .push<T>(context);

  @override
  Future<T?> openUserSpace<T>(BuildContext context, {required String name}) =>
      UserSpaceRoute(name: name).push<T>(context);

  @override
  Future<T?> openAnimePreview<T>(
    BuildContext context, {
    required List<String> images,
    String? title,
  }) =>
      AnimePreviewPageRoute(images: images, title: title).push<T>(context);

  @override
  Future<T?> openSearch<T>(BuildContext context, {String? keywords}) =>
      SearchRoute(keywords: keywords).push<T>(context);

  @override
  Future<String?> openImageSearch(BuildContext context) =>
      const ImageSearchRoute().push<String>(context);

  @override
  Future<T?> openCalendar<T>(BuildContext context) =>
      const CalendarRoute().push<T>(context);
  @override
  Future<T?> openDownload<T>(BuildContext context) =>
      const DownloadRoute().push<T>(context);
  @override
  Future<T?> openPlayRecord<T>(BuildContext context) =>
      const PlayRecordRoute().push<T>(context);
  @override
  void goToRecommend(BuildContext context) =>
      const RecommendRoute().go(context);

  @override
  Future<T?> openSettings<T>(
    BuildContext context, {
    SettingsDestination destination = SettingsDestination.menu,
  }) =>
      _settingsRoute(destination).push<T>(context);

  @override
  void replaceSettings(BuildContext context, SettingsDestination destination) =>
      _settingsRoute(destination).replace(context);

  @override
  void goToSettings(BuildContext context, SettingsDestination destination) =>
      _settingsRoute(destination).go(context);

  @override
  String settingsLocation(SettingsDestination destination) =>
      _settingsRoute(destination).location;

  @override
  SettingsDestination? settingsDestinationForLocation(String location) {
    final path = Uri.parse(location).path;
    for (final destination in SettingsDestination.values) {
      if (settingsLocation(destination) == path) return destination;
    }
    return null;
  }

  @override
  Future<T?> openPluginEditor<T>(BuildContext context,
          {String? editPluginKey}) =>
      SettingAddPluginsRoute(editPluginKey: editPluginKey).push<T>(context);

  GoRouteData _settingsRoute(SettingsDestination destination) =>
      switch (destination) {
        SettingsDestination.menu => const SettingsRoute(),
        SettingsDestination.account => const SettingAccountRoute(),
        SettingsDestination.logs => const SettingLogsRoute(),
        SettingsDestination.general => const SettingGeneralRoute(),
        SettingsDestination.page => const SettingPageRoute(),
        SettingsDestination.playback => const SettingPlaybackRoute(),
        SettingsDestination.playerShortcuts =>
          const SettingPlayerShortcutsRoute(),
        SettingsDestination.downloadPlugins =>
          const SettingDownloadPluginsRoute(),
        SettingsDestination.danmaku => const SettingDanmakuRoute(),
        SettingsDestination.download => const SettingDownloadRoute(),
        SettingsDestination.about => const SettingAboutRoute(),
        SettingsDestination.author => const SettingAuthorRoute(),
        SettingsDestination.updates => const SettingUpdatesRoute(),
        SettingsDestination.website => const SettingWebsiteRoute(),
        SettingsDestination.plugins => const SettingPluginsRoute(),
        SettingsDestination.addPlugins => const SettingAddPluginsRoute(),
        SettingsDestination.theme => const SettingThemeRoute(),
        SettingsDestination.font => const SettingFontRoute(),
        SettingsDestination.thanks => const SettingThanksRoute(),
        SettingsDestination.sponsor => const SettingSponsorRoute(),
        SettingsDestination.agreement => const SettingAgreementRoute(),
      };
}

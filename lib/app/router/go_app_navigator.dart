import 'package:anime_flow/shared/navigation/app_navigator.dart';
import 'package:anime_flow/shared/navigation/args/image_viewer_extra.dart';
import 'package:anime_flow/shared/navigation/args/wallpaper_detail_args.dart';
import 'package:anime_flow/shared/navigation/args/info_route_extra.dart';
import 'package:anime_flow/shared/navigation/args/character_info_extra.dart';
import 'package:anime_flow/shared/navigation/args/play_route_extra.dart';
import 'package:anime_flow/shared/navigation/settings_destination.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// 将导航请求转换为生成的类型安全路由调用。
///
/// 路由器由应用入口注入，必须与 MaterialApp.router 使用同一个实例。
/// Navigator 的归属由路由配置决定；本适配器不持有页面上下文。
class GoAppNavigator implements AppNavigator {
  const GoAppNavigator(this._router);

  final GoRouter _router;

  @override
  Future<T?> openRegister<T>() =>
      _router.push<T>(const RegisterRoute().location);

  @override
  Future<T?> openForgotPassword<T>() =>
      _router.push<T>(const ForgotPasswordRoute().location);

  @override
  void goToUser() => _router.go(const UserRoute().location);

  @override
  Future<T?> openWallpaper<T>(WallpaperDetailArgs args) =>
      _router.push<T>(WallpaperDetailRoute($extra: args).location, extra: args);

  @override
  Future<T?> openImagePreview<T>(ImageViewerRouteArgs args) =>
      _router.push<T>(ImagePreviewRoute.fromArgs(args).location, extra: args);

  @override
  Future<T?> openAnimeInfo<T>({
    required int id,
    required String name,
    required String image,
    InfoRouteExtra? extra,
  }) =>
      _router.push<T>(
          AnimeInfoRoute(id: id, name: name, image: image, $extra: extra)
              .location,
          extra: extra);

  @override
  Future<T?> openAnimeInfoFromExtra<T>(InfoRouteExtra extra) =>
      _router.push<T>(AnimeInfoRoute.fromExtra(extra).location, extra: extra);

  @override
  Future<T?> openPlay<T>(PlayRouteExtra args) =>
      _router.push<T>(PlayRoute.fromExtra(args).location, extra: args);

  @override
  Future<T?> openCharacters<T>({required int subjectsId}) =>
      _router.push<T>(CharactersRoute(subjectsId: subjectsId).location);

  @override
  Future<T?> openCharacterInfo<T>({
    required int id,
    required String name,
    required String image,
    CharacterInfoExtra? extra,
  }) =>
      _router.push<T>(
          CharacterInfoRoute(id: id, name: name, image: image, $extra: extra)
              .location,
          extra: extra);

  @override
  Future<T?> openUserSpace<T>({required String name}) =>
      _router.push<T>(UserSpaceRoute(name: name).location);

  @override
  Future<T?> openAnimePreview<T>({
    required List<String> images,
    String? title,
  }) =>
      _router.push<T>(
          AnimePreviewPageRoute(images: images, title: title).location);

  @override
  Future<T?> openSearch<T>({String? keywords}) =>
      _router.push<T>(SearchRoute(keywords: keywords).location);

  @override
  Future<String?> openImageSearch() =>
      _router.push<String>(const ImageSearchRoute().location);

  @override
  Future<T?> openCalendar<T>() =>
      _router.push<T>(const CalendarRoute().location);
  @override
  Future<T?> openDownload<T>() =>
      _router.push<T>(const DownloadRoute().location);
  @override
  Future<T?> openPlayRecord<T>() =>
      _router.push<T>(const PlayRecordRoute().location);
  @override
  void goToRecommend() => _router.go(const RecommendRoute().location);

  @override
  Future<T?> openSettings<T>({
    SettingsDestination destination = SettingsDestination.menu,
  }) =>
      _router.push<T>(_settingsRoute(destination).location);

  @override
  void replaceSettings(SettingsDestination destination) =>
      _router.replace(_settingsRoute(destination).location);

  @override
  void goToSettings(SettingsDestination destination) =>
      _router.go(_settingsRoute(destination).location);

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
  Future<T?> openPluginEditor<T>({String? editPluginKey}) => _router
      .push<T>(SettingAddPluginsRoute(editPluginKey: editPluginKey).location);

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

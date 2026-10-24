import 'package:flutter/widgets.dart';

import 'args/image_viewer_extra.dart';
import 'args/wallpaper_detail_args.dart';
import 'args/info_route_extra.dart';
import 'args/character_info_extra.dart';
import 'args/play_route_extra.dart';
import 'settings_destination.dart';

/// UI 层的导航接口，由应用层提供具体实现。
///
/// 本库不依赖具体路由类、页面组件或路由器实例。
/// 此接口仅供 UI 层使用，应用层和领域层的 Provider 不应依赖它。
abstract interface class AppNavigator {
  Future<T?> openRegister<T>(BuildContext context);

  Future<T?> openForgotPassword<T>(BuildContext context);

  /// 切换到用户分支，并替换当前路由配置。
  void goToUser(BuildContext context);

  Future<T?> openWallpaper<T>(BuildContext context, WallpaperDetailArgs args);

  Future<T?> openImagePreview<T>(
      BuildContext context, ImageViewerRouteArgs args);

  Future<T?> openAnimeInfo<T>(
    BuildContext context, {
    required int id,
    required String name,
    required String image,
    InfoRouteExtra? extra,
  });

  Future<T?> openAnimeInfoFromExtra<T>(
      BuildContext context, InfoRouteExtra extra);
  Future<T?> openPlay<T>(BuildContext context, PlayRouteExtra args);
  Future<T?> openCharacters<T>(BuildContext context, {required int subjectsId});
  Future<T?> openCharacterInfo<T>(
    BuildContext context, {
    required int id,
    required String name,
    required String image,
    CharacterInfoExtra? extra,
  });
  Future<T?> openUserSpace<T>(BuildContext context, {required String name});
  Future<T?> openAnimePreview<T>(
    BuildContext context, {
    required List<String> images,
    String? title,
  });
  Future<T?> openSearch<T>(BuildContext context, {String? keywords});
  Future<String?> openImageSearch(BuildContext context);
  Future<T?> openCalendar<T>(BuildContext context);
  Future<T?> openDownload<T>(BuildContext context);
  Future<T?> openPlayRecord<T>(BuildContext context);
  void goToRecommend(BuildContext context);

  Future<T?> openSettings<T>(
    BuildContext context, {
    SettingsDestination destination = SettingsDestination.menu,
  });
  void replaceSettings(BuildContext context, SettingsDestination destination);
  void goToSettings(BuildContext context, SettingsDestination destination);
  String settingsLocation(SettingsDestination destination);
  SettingsDestination? settingsDestinationForLocation(String location);
  Future<T?> openPluginEditor<T>(BuildContext context, {String? editPluginKey});
}

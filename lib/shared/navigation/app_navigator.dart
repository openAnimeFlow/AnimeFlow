import 'args/image_viewer_extra.dart';
import 'args/wallpaper_detail_args.dart';
import 'args/info_route_extra.dart';
import 'args/character_info_extra.dart';
import 'args/play_route_extra.dart';
import 'settings_destination.dart';

/// UI 层的导航接口，由应用层提供具体实现。
///
/// 本库不依赖 BuildContext、具体路由类、页面组件或路由器实例。
/// 此接口仅供 UI 层使用，应用层和领域层的 Provider 不应依赖它。
abstract interface class AppNavigator {
  Future<T?> openRegister<T>();

  Future<T?> openForgotPassword<T>();

  /// 切换到用户分支，并替换当前路由配置。
  void goToUser();

  Future<T?> openWallpaper<T>(WallpaperDetailArgs args);

  Future<T?> openImagePreview<T>(ImageViewerRouteArgs args);

  Future<T?> openAnimeInfo<T>({
    required int id,
    required String name,
    required String image,
    InfoRouteExtra? extra,
  });

  Future<T?> openAnimeInfoFromExtra<T>(InfoRouteExtra extra);
  Future<T?> openPlay<T>(PlayRouteExtra args);
  Future<T?> openCharacters<T>({required int subjectsId});
  Future<T?> openCharacterInfo<T>({
    required int id,
    required String name,
    required String image,
    CharacterInfoExtra? extra,
  });
  Future<T?> openUserSpace<T>({required String name});
  Future<T?> openAnimePreview<T>({
    required List<String> images,
    String? title,
  });
  Future<T?> openSearch<T>({String? keywords});
  Future<String?> openImageSearch();
  Future<T?> openCalendar<T>();
  Future<T?> openDownload<T>();
  Future<T?> openPlayRecord<T>();
  void goToRecommend();

  Future<T?> openSettings<T>({
    SettingsDestination destination = SettingsDestination.menu,
  });
  void replaceSettings(SettingsDestination destination);
  void goToSettings(SettingsDestination destination);
  String settingsLocation(SettingsDestination destination);
  SettingsDestination? settingsDestinationForLocation(String location);
  Future<T?> openPluginEditor<T>({String? editPluginKey});
}

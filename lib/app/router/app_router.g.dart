// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
      $mainShellRoute,
      $loginRoute,
      $registerRoute,
      $forgotPasswordRoute,
      $oauthCallbackRoute,
      $animeInfoRoute,
      $playRoute,
      $searchRoute,
      $calendarRoute,
      $charactersRoute,
      $characterInfoRoute,
      $playRecordRoute,
      $downloadRoute,
      $userSpaceRoute,
      $imageSearchRoute,
      $settingsRoute,
      $settingAccountRoute,
      $settingLogsRoute,
      $settingGeneralRoute,
      $settingPlaybackRoute,
      $settingDownloadPluginsRoute,
      $settingDanmakuRoute,
      $settingDownloadRoute,
      $settingAboutRoute,
      $settingPluginsRoute,
      $settingAddPluginsRoute,
      $settingThemeRoute,
      $settingFontRoute,
      $settingThanksRoute,
      $settingAgreementRoute,
    ];

RouteBase get $mainShellRoute => StatefulShellRouteData.$route(
      factory: $MainShellRouteExtension._fromState,
      branches: [
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/recommend',
              hasOverriddenOnExit: false,
              factory: $RecommendRoute._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/ranking',
              hasOverriddenOnExit: false,
              factory: $RankingRoute._fromState,
            ),
          ],
        ),
        StatefulShellBranchData.$branch(
          routes: [
            GoRouteData.$route(
              path: '/user',
              hasOverriddenOnExit: false,
              factory: $UserRoute._fromState,
            ),
          ],
        ),
      ],
    );

extension $MainShellRouteExtension on MainShellRoute {
  static MainShellRoute _fromState(GoRouterState state) =>
      const MainShellRoute();
}

mixin $RecommendRoute on GoRouteData {
  static RecommendRoute _fromState(GoRouterState state) =>
      const RecommendRoute();

  @override
  String get location => GoRouteData.$location(
        '/recommend',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RankingRoute on GoRouteData {
  static RankingRoute _fromState(GoRouterState state) => const RankingRoute();

  @override
  String get location => GoRouteData.$location(
        '/ranking',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $UserRoute on GoRouteData {
  static UserRoute _fromState(GoRouterState state) => const UserRoute();

  @override
  String get location => GoRouteData.$location(
        '/user',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $loginRoute => GoRouteData.$route(
      path: '/login',
      hasOverriddenOnExit: false,
      factory: $LoginRoute._fromState,
    );

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location(
        '/login',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $registerRoute => GoRouteData.$route(
      path: '/register',
      hasOverriddenOnExit: false,
      factory: $RegisterRoute._fromState,
    );

mixin $RegisterRoute on GoRouteData {
  static RegisterRoute _fromState(GoRouterState state) => const RegisterRoute();

  @override
  String get location => GoRouteData.$location(
        '/register',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $forgotPasswordRoute => GoRouteData.$route(
      path: '/forgot_password',
      hasOverriddenOnExit: false,
      factory: $ForgotPasswordRoute._fromState,
    );

mixin $ForgotPasswordRoute on GoRouteData {
  static ForgotPasswordRoute _fromState(GoRouterState state) =>
      const ForgotPasswordRoute();

  @override
  String get location => GoRouteData.$location(
        '/forgot_password',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $oauthCallbackRoute => GoRouteData.$route(
      path: '/oauth/callback',
      hasOverriddenOnExit: false,
      factory: $OauthCallbackRoute._fromState,
    );

mixin $OauthCallbackRoute on GoRouteData {
  static OauthCallbackRoute _fromState(GoRouterState state) =>
      const OauthCallbackRoute();

  @override
  String get location => GoRouteData.$location(
        '/oauth/callback',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $animeInfoRoute => GoRouteData.$route(
      path: '/anime_info',
      hasOverriddenOnExit: false,
      factory: $AnimeInfoRoute._fromState,
    );

mixin $AnimeInfoRoute on GoRouteData {
  static AnimeInfoRoute _fromState(GoRouterState state) => AnimeInfoRoute(
        id: int.parse(state.uri.queryParameters['id']!),
        name: state.uri.queryParameters['name']!,
        image: state.uri.queryParameters['image']!,
        $extra: state.extra as InfoRouteExtra?,
      );

  AnimeInfoRoute get _self => this as AnimeInfoRoute;

  @override
  String get location => GoRouteData.$location(
        '/anime_info',
        queryParams: {
          'id': _self.id.toString(),
          'name': _self.name,
          'image': _self.image,
        },
      );

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $playRoute => GoRouteData.$route(
      path: '/play',
      hasOverriddenOnExit: false,
      factory: $PlayRoute._fromState,
    );

mixin $PlayRoute on GoRouteData {
  static PlayRoute _fromState(GoRouterState state) => PlayRoute(
        id: int.parse(state.uri.queryParameters['id']!),
        name: state.uri.queryParameters['name']!,
        image: state.uri.queryParameters['image']!,
        continueEpisodeId: _$convertMapValue(
            'continue-episode-id', state.uri.queryParameters, int.tryParse),
        $extra: state.extra as PlayRouteExtra?,
      );

  PlayRoute get _self => this as PlayRoute;

  @override
  String get location => GoRouteData.$location(
        '/play',
        queryParams: {
          'id': _self.id.toString(),
          'name': _self.name,
          'image': _self.image,
          if (_self.continueEpisodeId != null)
            'continue-episode-id': _self.continueEpisodeId!.toString(),
        },
      );

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

RouteBase get $searchRoute => GoRouteData.$route(
      path: '/search',
      hasOverriddenOnExit: false,
      factory: $SearchRoute._fromState,
    );

mixin $SearchRoute on GoRouteData {
  static SearchRoute _fromState(GoRouterState state) => SearchRoute(
        keywords: state.uri.queryParameters['keywords'],
      );

  SearchRoute get _self => this as SearchRoute;

  @override
  String get location => GoRouteData.$location(
        '/search',
        queryParams: {
          if (_self.keywords != null) 'keywords': _self.keywords,
        },
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $calendarRoute => GoRouteData.$route(
      path: '/calendar',
      hasOverriddenOnExit: false,
      factory: $CalendarRoute._fromState,
    );

mixin $CalendarRoute on GoRouteData {
  static CalendarRoute _fromState(GoRouterState state) => const CalendarRoute();

  @override
  String get location => GoRouteData.$location(
        '/calendar',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $charactersRoute => GoRouteData.$route(
      path: '/characters',
      hasOverriddenOnExit: false,
      factory: $CharactersRoute._fromState,
    );

mixin $CharactersRoute on GoRouteData {
  static CharactersRoute _fromState(GoRouterState state) => CharactersRoute(
        subjectsId: int.parse(state.uri.queryParameters['subjects-id']!),
      );

  CharactersRoute get _self => this as CharactersRoute;

  @override
  String get location => GoRouteData.$location(
        '/characters',
        queryParams: {
          'subjects-id': _self.subjectsId.toString(),
        },
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $characterInfoRoute => GoRouteData.$route(
      path: '/character_info',
      hasOverriddenOnExit: false,
      factory: $CharacterInfoRoute._fromState,
    );

mixin $CharacterInfoRoute on GoRouteData {
  static CharacterInfoRoute _fromState(GoRouterState state) =>
      CharacterInfoRoute(
        id: int.parse(state.uri.queryParameters['id']!),
        name: state.uri.queryParameters['name']!,
        image: state.uri.queryParameters['image']!,
      );

  CharacterInfoRoute get _self => this as CharacterInfoRoute;

  @override
  String get location => GoRouteData.$location(
        '/character_info',
        queryParams: {
          'id': _self.id.toString(),
          'name': _self.name,
          'image': _self.image,
        },
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $playRecordRoute => GoRouteData.$route(
      path: '/play_record',
      hasOverriddenOnExit: false,
      factory: $PlayRecordRoute._fromState,
    );

mixin $PlayRecordRoute on GoRouteData {
  static PlayRecordRoute _fromState(GoRouterState state) =>
      const PlayRecordRoute();

  @override
  String get location => GoRouteData.$location(
        '/play_record',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $downloadRoute => GoRouteData.$route(
      path: '/download',
      hasOverriddenOnExit: false,
      factory: $DownloadRoute._fromState,
    );

mixin $DownloadRoute on GoRouteData {
  static DownloadRoute _fromState(GoRouterState state) => const DownloadRoute();

  @override
  String get location => GoRouteData.$location(
        '/download',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $userSpaceRoute => GoRouteData.$route(
      path: '/user_space',
      hasOverriddenOnExit: false,
      factory: $UserSpaceRoute._fromState,
    );

mixin $UserSpaceRoute on GoRouteData {
  static UserSpaceRoute _fromState(GoRouterState state) => UserSpaceRoute(
        name: state.uri.queryParameters['name']!,
      );

  UserSpaceRoute get _self => this as UserSpaceRoute;

  @override
  String get location => GoRouteData.$location(
        '/user_space',
        queryParams: {
          'name': _self.name,
        },
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $imageSearchRoute => GoRouteData.$route(
      path: '/image_search',
      hasOverriddenOnExit: false,
      factory: $ImageSearchRoute._fromState,
    );

mixin $ImageSearchRoute on GoRouteData {
  static ImageSearchRoute _fromState(GoRouterState state) =>
      const ImageSearchRoute();

  @override
  String get location => GoRouteData.$location(
        '/image_search',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingsRoute => GoRouteData.$route(
      path: '/settings',
      hasOverriddenOnExit: false,
      factory: $SettingsRoute._fromState,
    );

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingAccountRoute => GoRouteData.$route(
      path: '/settings/account',
      hasOverriddenOnExit: false,
      factory: $SettingAccountRoute._fromState,
    );

mixin $SettingAccountRoute on GoRouteData {
  static SettingAccountRoute _fromState(GoRouterState state) =>
      const SettingAccountRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/account',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingLogsRoute => GoRouteData.$route(
      path: '/settings/logs',
      hasOverriddenOnExit: false,
      factory: $SettingLogsRoute._fromState,
    );

mixin $SettingLogsRoute on GoRouteData {
  static SettingLogsRoute _fromState(GoRouterState state) =>
      const SettingLogsRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/logs',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingGeneralRoute => GoRouteData.$route(
      path: '/settings/general',
      hasOverriddenOnExit: false,
      factory: $SettingGeneralRoute._fromState,
    );

mixin $SettingGeneralRoute on GoRouteData {
  static SettingGeneralRoute _fromState(GoRouterState state) =>
      const SettingGeneralRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/general',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingPlaybackRoute => GoRouteData.$route(
      path: '/settings/playback',
      hasOverriddenOnExit: false,
      factory: $SettingPlaybackRoute._fromState,
    );

mixin $SettingPlaybackRoute on GoRouteData {
  static SettingPlaybackRoute _fromState(GoRouterState state) =>
      const SettingPlaybackRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/playback',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingDownloadPluginsRoute => GoRouteData.$route(
      path: '/settings/downloadPlugins',
      hasOverriddenOnExit: false,
      factory: $SettingDownloadPluginsRoute._fromState,
    );

mixin $SettingDownloadPluginsRoute on GoRouteData {
  static SettingDownloadPluginsRoute _fromState(GoRouterState state) =>
      const SettingDownloadPluginsRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/downloadPlugins',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingDanmakuRoute => GoRouteData.$route(
      path: '/settings/danmaku',
      hasOverriddenOnExit: false,
      factory: $SettingDanmakuRoute._fromState,
    );

mixin $SettingDanmakuRoute on GoRouteData {
  static SettingDanmakuRoute _fromState(GoRouterState state) =>
      const SettingDanmakuRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/danmaku',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingDownloadRoute => GoRouteData.$route(
      path: '/settings/download',
      hasOverriddenOnExit: false,
      factory: $SettingDownloadRoute._fromState,
    );

mixin $SettingDownloadRoute on GoRouteData {
  static SettingDownloadRoute _fromState(GoRouterState state) =>
      const SettingDownloadRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/download',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingAboutRoute => GoRouteData.$route(
      path: '/settings/about',
      hasOverriddenOnExit: false,
      factory: $SettingAboutRoute._fromState,
    );

mixin $SettingAboutRoute on GoRouteData {
  static SettingAboutRoute _fromState(GoRouterState state) =>
      const SettingAboutRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/about',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingPluginsRoute => GoRouteData.$route(
      path: '/settings/Plugins',
      hasOverriddenOnExit: false,
      factory: $SettingPluginsRoute._fromState,
    );

mixin $SettingPluginsRoute on GoRouteData {
  static SettingPluginsRoute _fromState(GoRouterState state) =>
      const SettingPluginsRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/Plugins',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingAddPluginsRoute => GoRouteData.$route(
      path: '/settings/addPlugins',
      hasOverriddenOnExit: false,
      factory: $SettingAddPluginsRoute._fromState,
    );

mixin $SettingAddPluginsRoute on GoRouteData {
  static SettingAddPluginsRoute _fromState(GoRouterState state) =>
      SettingAddPluginsRoute(
        editPluginKey: state.uri.queryParameters['edit-plugin-key'],
      );

  SettingAddPluginsRoute get _self => this as SettingAddPluginsRoute;

  @override
  String get location => GoRouteData.$location(
        '/settings/addPlugins',
        queryParams: {
          if (_self.editPluginKey != null)
            'edit-plugin-key': _self.editPluginKey,
        },
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingThemeRoute => GoRouteData.$route(
      path: '/settings/theme',
      hasOverriddenOnExit: false,
      factory: $SettingThemeRoute._fromState,
    );

mixin $SettingThemeRoute on GoRouteData {
  static SettingThemeRoute _fromState(GoRouterState state) =>
      const SettingThemeRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/theme',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingFontRoute => GoRouteData.$route(
      path: '/settings/font',
      hasOverriddenOnExit: false,
      factory: $SettingFontRoute._fromState,
    );

mixin $SettingFontRoute on GoRouteData {
  static SettingFontRoute _fromState(GoRouterState state) =>
      const SettingFontRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/font',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingThanksRoute => GoRouteData.$route(
      path: '/settings/thanks',
      hasOverriddenOnExit: false,
      factory: $SettingThanksRoute._fromState,
    );

mixin $SettingThanksRoute on GoRouteData {
  static SettingThanksRoute _fromState(GoRouterState state) =>
      const SettingThanksRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/thanks',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingAgreementRoute => GoRouteData.$route(
      path: '/settings/agreement',
      hasOverriddenOnExit: false,
      factory: $SettingAgreementRoute._fromState,
    );

mixin $SettingAgreementRoute on GoRouteData {
  static SettingAgreementRoute _fromState(GoRouterState state) =>
      const SettingAgreementRoute();

  @override
  String get location => GoRouteData.$location(
        '/settings/agreement',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

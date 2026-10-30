import 'package:anime_flow/app/router/go_app_navigator.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/args/image_viewer_extra.dart';
import 'package:anime_flow/shared/navigation/args/wallpaper_detail_args.dart';
import 'package:anime_flow/shared/navigation/args/play_route_extra.dart';
import 'package:anime_flow/shared/navigation/args/character_info_extra.dart';
import 'package:anime_flow/shared/navigation/settings_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;
  late Map<String, GoRouterState> states;

  setUp(() {
    states = {};
    // 使用轻量的目标页面测试实际导航适配器。
    // 路由器属于当前组件树，不使用全局 appRouter。
    router = GoRouter(
      initialLocation: '/login',
      routes: [
        for (final path in [
          '/login',
          '/register',
          '/forgot_password',
          '/user',
          '/wallpaper',
          '/image-preview',
          '/anime_info',
          '/play',
          '/character_info',
          '/image_search',
          '/settings',
          '/settings/general',
          '/settings/playback',
          '/settings/addPlugins',
        ])
          GoRoute(
            path: path,
            builder: (context, state) {
              states[path] = state;
              return Scaffold(
                key: ValueKey(path),
                body: Text(path),
              );
            },
          ),
      ],
    );
  });

  tearDown(() => router.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [overrideAppNavigator(GoAppNavigator(router))],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  BuildContext pageContext(WidgetTester tester, String path) =>
      tester.element(find.byKey(ValueKey(path)));

  testWidgets('navigation resolves the local scope without a router context',
      (tester) async {
    final secondRouter = GoRouter(
      initialLocation: '/login',
      routes: [
        for (final path in ['/login', '/register'])
          GoRoute(
            path: path,
            builder: (context, state) => Scaffold(body: Text('second $path')),
          ),
      ],
    );
    addTearDown(secondRouter.dispose);
    late BuildContext firstContext;
    late BuildContext secondContext;
    await tester.pumpWidget(ProviderScope(
      overrides: [overrideAppNavigator(GoAppNavigator(router))],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          Expanded(
            child: Builder(builder: (context) {
              firstContext = context;
              return MaterialApp.router(routerConfig: router);
            }),
          ),
          Expanded(
            child: ProviderScope(
              overrides: [overrideAppNavigator(GoAppNavigator(secondRouter))],
              child: Builder(builder: (context) {
                secondContext = context;
                return MaterialApp.router(routerConfig: secondRouter);
              }),
            ),
          ),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    // Both lookup contexts are above MaterialApp.router. Only ProviderScope
    // selects the navigator; navigation must not look up GoRouter from them.
    expect(GoRouter.maybeOf(firstContext), isNull);
    expect(GoRouter.maybeOf(secondContext), isNull);
    final registration = appNavigatorOf(secondContext).openRegister<String>();
    await tester.pumpAndSettle();
    expect(find.text('second /register'), findsOneWidget);
    expect(find.byKey(const ValueKey('/login')), findsOneWidget);
    expect(router.canPop(), isFalse);
    secondRouter.pop('registered');
    await tester.pumpAndSettle();
    expect(await registration, 'registered');

    appNavigatorOf(firstContext).goToUser();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/user')), findsOneWidget);
    expect(find.text('second /login'), findsOneWidget);
    expect(secondRouter.canPop(), isFalse);
  });

  testWidgets('auth pushes preserve the previous page and typed results',
      (tester) async {
    await pumpApp(tester);
    final context = pageContext(tester, '/login');
    final navigation = appNavigatorOf(context);

    final registration = navigation.openRegister<String>();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/register')), findsOneWidget);
    expect(router.canPop(), isTrue);
    router.pop('registered');
    await tester.pumpAndSettle();
    expect(await registration, 'registered');
    expect(find.byKey(const ValueKey('/login')), findsOneWidget);

    final recovery = navigation.openForgotPassword<bool>();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/forgot_password')), findsOneWidget);
    expect(router.canPop(), isTrue);
    router.pop(true);
    await tester.pumpAndSettle();
    expect(await recovery, isTrue);
    expect(find.byKey(const ValueKey('/login')), findsOneWidget);
  });

  testWidgets('goToUser replaces the auth stack instead of pushing',
      (tester) async {
    await pumpApp(tester);
    final context = pageContext(tester, '/login');
    final navigation = appNavigatorOf(context);
    navigation.openRegister<void>();
    await tester.pumpAndSettle();

    navigation.goToUser();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/user')), findsOneWidget);
    expect(find.byKey(const ValueKey('/login')), findsNothing);
    expect(find.byKey(const ValueKey('/register')), findsNothing);
    expect(router.canPop(), isFalse);
  });

  testWidgets('anime navigation preserves and encodes query parameters',
      (tester) async {
    await pumpApp(tester);
    final context = pageContext(tester, '/login');
    const name = '动画 & special?';
    const image = 'https://example.com/cover.jpg?size=large&index=1';
    final result = appNavigatorOf(context).openAnimeInfo<void>(
      id: 42,
      name: name,
      image: image,
    );
    await tester.pumpAndSettle();
    expect(states['/anime_info']!.uri.queryParameters, {
      'id': '42',
      'name': name,
      'image': image,
    });
    router.pop();
    await tester.pumpAndSettle();
    await result;
  });

  testWidgets('wallpaper and preview navigation preserve extra objects',
      (tester) async {
    await pumpApp(tester);
    final context = pageContext(tester, '/login');
    final navigation = appNavigatorOf(context);
    final wallpaper = WallpaperDetailArgs(
      subject: SubjectWallpaper.fromJson({'subjectId': 42}),
      initialUrl: 'https://example.com/wallpaper.jpg',
    );
    final detail = navigation.openWallpaper<void>(wallpaper);
    await tester.pumpAndSettle();
    expect(states['/wallpaper']!.extra, same(wallpaper));

    final images = ImageViewerRouteArgs(
      imageUrls: [wallpaper.initialUrl],
      heroTag: 'wallpaper',
    );
    final preview = navigation.openImagePreview<int>(
      images,
    );
    await tester.pumpAndSettle();
    expect(states['/image-preview']!.extra, same(images));
    router.pop(0);
    await tester.pumpAndSettle();
    expect(await preview, 0);
    expect(find.byKey(const ValueKey('/wallpaper')), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await detail;
  });

  testWidgets('offline playback preserves session data and resume parameters',
      (tester) async {
    await pumpApp(tester);
    final context = pageContext(tester, '/login');
    const args = PlayRouteExtra(
      playExtra: PlayExtra(
          subjectId: 42,
          subjectName: '测试',
          subjectCover: 'cover',
          subjectAliases: ['alias']),
      continueEpisodeId: 100,
      isOfflineMode: true,
      offlineMediaPath: 'C:/downloads/episode.mkv',
      offlineDanmakuPath: 'C:/downloads/episode.xml',
      offlineEpisodeUrl: 'offline://episode',
    );
    final playback = appNavigatorOf(context).openPlay<bool>(args);
    await tester.pumpAndSettle();
    expect(states['/play']!.extra, same(args));
    expect(states['/play']!.uri.queryParameters, {
      'id': '42',
      'name': '测试',
      'image': 'cover',
      'continue-episode-id': '100',
    });
    router.pop(true);
    await tester.pumpAndSettle();
    expect(await playback, isTrue);
  });

  testWidgets('character query names stay independent of optional extra names',
      (tester) async {
    await pumpApp(tester);
    final context = pageContext(tester, '/login');
    const extra = CharacterInfoExtra(
        characterId: 7, characterName: 'Original', characterImage: 'image');
    final detail = appNavigatorOf(context).openCharacterInfo<void>(
      id: 7,
      name: '译名',
      image: 'image',
      extra: extra,
    );
    await tester.pumpAndSettle();
    expect(states['/character_info']!.uri.queryParameters['name'], '译名');
    expect(states['/character_info']!.extra, same(extra));
    router.pop();
    await tester.pumpAndSettle();
    await detail;
  });

  testWidgets('image search returns its selected keyword', (tester) async {
    await pumpApp(tester);
    final context = pageContext(tester, '/login');
    final keyword = appNavigatorOf(context).openImageSearch();
    await tester.pumpAndSettle();
    router.pop('selected anime');
    await tester.pumpAndSettle();
    expect(await keyword, 'selected anime');
  });

  testWidgets('settings push and replace preserve the expected back stack',
      (tester) async {
    await pumpApp(tester);
    final context = pageContext(tester, '/login');
    final navigation = appNavigatorOf(context);
    navigation.openSettings<void>();
    await tester.pumpAndSettle();
    navigation.openSettings<void>(destination: SettingsDestination.general);
    await tester.pumpAndSettle();
    final pageKey = states['/settings/general']!.pageKey;
    navigation.replaceSettings(SettingsDestination.playback);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/settings/playback')), findsOneWidget);
    expect(states['/settings/playback']!.pageKey, pageKey);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/settings')), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/login')), findsOneWidget);
  });

  testWidgets('settings destination lookup handles plugin query strings',
      (tester) async {
    await pumpApp(tester);
    final context = pageContext(tester, '/login');
    final navigation = appNavigatorOf(context);
    final editor = navigation.openPluginEditor<void>(editPluginKey: '来源 & 1');
    await tester.pumpAndSettle();
    final uri = states['/settings/addPlugins']!.uri;
    expect(uri.queryParameters['edit-plugin-key'], '来源 & 1');
    expect(navigation.settingsDestinationForLocation(uri.toString()),
        SettingsDestination.addPlugins);
    expect(navigation.settingsLocation(SettingsDestination.plugins),
        '/settings/Plugins');
    expect(navigation.settingsDestinationForLocation('/unknown'), isNull);
    router.pop();
    await tester.pumpAndSettle();
    await editor;
  });
}

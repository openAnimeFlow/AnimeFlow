import 'package:anime_flow/app/router/go_app_navigator.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/localization/app_localizations_delegates.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/settings/presentation/pages/settings_page.dart';
import 'package:anime_flow/features/user/user_api.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class _GuestUser extends CurrentUserInfo {
  @override
  Future<FlowUsers?> build() async => null;
}

// 设置页外壳在运行时提供布局作用域，测试中的路由回调沿用该作用域。
void main() {
  Future<GoRouter> pumpSettings(
      WidgetTester tester, double width, String location) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(initialLocation: location, routes: [
      ShellRoute(
          builder: (context, state, child) =>
              SettingsPage(location: state.uri.path, child: child),
          routes: [
            GoRoute(
                path: '/settings',
                builder: (context, state) =>
                    // 窄屏测试使用实际菜单，宽屏测试使用实际外壳菜单。
                    // 替换子页面，避免启动其中的账号和网络服务。
                    width > 600 ? const SizedBox() : const SettingsMenuPage(),
                routes: [
                  for (final path in ['general', 'playback', 'font'])
                    GoRoute(
                        path: path,
                        builder: (context, state) =>
                            SizedBox(key: ValueKey(path))),
                ]),
          ]),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          overrideAppNavigator(const GoAppNavigator()),
          currentUserInfoProvider.overrideWith(_GuestUser.new),
          isLoggedInProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        )));
    await tester.pumpAndSettle();
    return router;
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(SettingsPage)));

  testWidgets('narrow settings menu pushes a category and returns to menu',
      (tester) async {
    final router = await pumpSettings(tester, 500, '/settings');
    await tester.tap(find.text(l10n(tester).generalSettingsTitle));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('general')), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text(l10n(tester).generalSettingsTitle), findsOneWidget);
  });

  testWidgets('wide menu replaces categories instead of growing the stack',
      (tester) async {
    final router = await pumpSettings(tester, 1000, '/settings/general');
    final label = l10n(tester).playbackSettings;
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('playback')), findsOneWidget);
    final tile = tester.widget<ListTile>(
        find.ancestor(of: find.text(label), matching: find.byType(ListTile)));
    expect(tile.selected, isTrue);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('general')), findsNothing);
    expect(find.byKey(const ValueKey('playback')), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/settings');
  });

  testWidgets('font detail keeps the theme category selected', (tester) async {
    await pumpSettings(tester, 1000, '/settings/font');
    final tile = tester.widget<ListTile>(find.ancestor(
        of: find.text(l10n(tester).themeStyle),
        matching: find.byType(ListTile)));
    expect(tile.selected, isTrue);
  });
}

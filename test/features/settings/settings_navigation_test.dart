import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/features/settings/presentation/pages/settings_page.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Keep production route paths and shell; isolate settings services from routing.
GoRoute _probeRoute(GoRoute route) => GoRoute(
      path: route.path,
      routes: route.routes.cast<GoRoute>().map(_probeRoute).toList(),
      builder: (context, state) => route.path == '/settings'
          ? Consumer(
              builder: (context, ref, child) =>
                  ref.watch(settingsLayoutProvider)
                      ? const Scaffold(body: Text('Default category'))
                      : const SettingsMenuPage())
          : _Probe(location: state.uri.path),
    );

class _Probe extends ConsumerStatefulWidget {
  const _Probe({required this.location});
  final String location;
  @override
  ConsumerState<_Probe> createState() => _ProbeState();
}

class _ProbeState extends ConsumerState<_Probe> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('probe:${widget.location}')),
        body: Column(children: [
          Text(ref.watch(settingsLayoutProvider)
              ? 'wide scope'
              : 'narrow scope'),
          TextField(controller: controller),
          TextButton(
              onPressed: () => const SettingFontRoute().push(context),
              child: const Text('Open font')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Return result')),
        ]),
      );
}

void main() {
  late GoRouter router;
  Future<void> mount(WidgetTester tester,
      {double width = 1000, String initial = '/'}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = $settingsShellRoute as ShellRoute;
    router = GoRouter(initialLocation: initial, routes: [
      GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
              body: TextButton(
                  onPressed: () => const SettingsRoute().push(context),
                  child: const Text('Enter settings')))),
      ShellRoute(
        builder: (context, state, child) =>
            const SettingsShellRoute().builder(context, state, child),
        routes: source.routes.cast<GoRoute>().map(_probeRoute).toList(),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    )));
    await tester.pumpAndSettle();
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(SettingsPage)));

  testWidgets(
      'wide child routes retain menu and category replacement preserves outer return',
      (tester) async {
    await mount(tester);
    await tester.tap(find.text('Enter settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n(tester).themeStyle));
    await tester.pumpAndSettle();
    expect(find.text('probe:/settings/theme'), findsOneWidget);
    await tester.tap(find.text('Open font'));
    await tester.pumpAndSettle();
    expect(find.text('probe:/settings/font'), findsOneWidget);
    expect(find.text(l10n(tester).themeStyle), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('probe:/settings/theme'), findsOneWidget);
    await tester.tap(find.text(l10n(tester).generalSettingsTitle));
    await tester.pumpAndSettle();
    expect(find.text('probe:/settings/general'), findsOneWidget);
    await tester.tap(find.text(l10n(tester).settingsLabel));
    await tester.pumpAndSettle();
    expect(find.text('Enter settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'narrow category and subpage return to menu then originating page',
      (tester) async {
    await mount(tester, width: 400);
    await tester.tap(find.text('Enter settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n(tester).themeStyle));
    await tester.pumpAndSettle();
    expect(find.text('narrow scope'), findsOneWidget);
    await tester.tap(find.text('Open font'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('probe:/settings/theme'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(l10n(tester).themeStyle), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Enter settings'), findsOneWidget);
  });

  testWidgets('resizing preserves child route, form state and scoped layout',
      (tester) async {
    await mount(tester, initial: '/settings/font');
    await tester.enterText(find.byType(TextField), 'keep this');
    final state = tester.state(find.byType(_Probe));
    tester.view.physicalSize = const Size(400, 900);
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(_Probe)), same(state));
    expect(find.text('keep this'), findsOneWidget);
    expect(find.text('narrow scope'), findsOneWidget);
    tester.view.physicalSize = const Size(1000, 900);
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(_Probe)), same(state));
    expect(find.text('wide scope'), findsOneWidget);
    expect(find.text(l10n(tester).themeStyle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('child navigation returns values to caller', (tester) async {
    await mount(tester, initial: '/settings/theme');
    final context = tester.element(find.byType(_Probe));
    final result = const SettingAddPluginsRoute(editPluginKey: 'source')
        .push<bool>(context);
    await tester.pumpAndSettle();
    expect(find.text('probe:/settings/addPlugins'), findsOneWidget);
    await tester.tap(find.text('Return result'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(find.text('probe:/settings/theme'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/info_appBar.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _LoadingInfo extends AnimeInfo {
  @override
  Future<SubjectsInfoItem> build() => Completer<SubjectsInfoItem>().future;
}

void main() {
  testWidgets('detail back pops the embedded navigator, preserving the player',
      (tester) async {
    final nestedKey = GlobalKey<NavigatorState>();
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home'))),
      GoRoute(
        path: '/player',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Player')),
          body: Navigator(
            key: nestedKey,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => const Center(child: Text('Introduction')),
            ),
          ),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        animeInfoArgsProvider.overrideWithValue(
          InfoRouteExtra(id: 1, name: 'Subject', image: ''),
        ),
        animeInfoProvider.overrideWith(_LoadingInfo.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    router.push<void>('/player');
    await tester.pumpAndSettle();
    nestedKey.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(
        body: SafeArea(child: InfoAppbar(isPinned: false)),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Player'), findsOneWidget);
    expect(find.text('Introduction'), findsOneWidget);
    expect(nestedKey.currentState!.canPop(), isFalse);
    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

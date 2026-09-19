import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/settings/presentation/widgets/account/bgm_collection_sync_section.dart';
import 'package:anime_flow/features/user/application/collection_sync_lifecycle.dart';
import 'package:anime_flow/features/user/data/repository/collection_sync_repository.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/shared/models/flow/bangumi_bind_item.dart';
import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'bgm_collection_sync_provider_test.dart' show Token, Profile, Repository;

const waiting = BgmCollectionSyncStatusItem(
    status: BgmCollectionSyncStatus.waitingConflict,
    taskId: 1,
    pendingConflictCount: 1);

void main() {
  for (final accountPath in ['/settings', '/settings/account']) {
    testWidgets(
        'polls only on $accountPath and late responses cannot restart it after exit',
        (tester) async {
      final repo = Repository()..loader = (() async => waiting);
      final c = ProviderContainer(overrides: [
        currentFlowTokenProvider.overrideWith(Token.new),
        currentUserInfoProvider.overrideWith(Profile.new),
        bangumiBindProvider.overrideWith(
            (ref) async => const BangumiBindItem(bound: true, platformUid: 1)),
        collectionSyncRepositoryProvider.overrideWithValue(repo),
      ]);
      final router = GoRouter(routes: [
        GoRoute(
            path: '/', builder: (_, __) => const Scaffold(body: Text('Home'))),
        ShellRoute(builder: (_, __, child) => child, routes: [
          GoRoute(
              path: '/settings',
              builder: (_, __) =>
                  const Scaffold(body: BangumiCollectionSyncSection()),
              routes: [
                GoRoute(
                    path: 'account',
                    builder: (_, __) =>
                        const Scaffold(body: BangumiCollectionSyncSection()))
              ]),
        ]),
        GoRoute(
            path: '/other',
            builder: (_, __) => const Scaffold(body: Text('Other'))),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (_, child) => CollectionSyncLifecycle(child: child!),
          )));
      await tester.pumpAndSettle();
      expect(repo.reads, 1);
      await tester.pump(const Duration(seconds: 30));
      expect(repo.reads, 1); // Global discovery must not poll waiting tasks.
      unawaited(router.push(accountPath));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<OutlinedButton>(
                  find.byKey(const ValueKey('start-bangumi-sync')))
              .onPressed,
          isNull);
      final entered = repo.reads;
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      expect(repo.reads, entered + 1);
      unawaited(
          router.push('/other')); // Account route remains mounted underneath.
      await tester.pumpAndSettle();
      final left = repo.reads;
      await tester.pump(const Duration(seconds: 30));
      expect(repo.reads, left);
      router.pop();
      await tester.pumpAndSettle();
      expect(repo.reads, left + 1); // One immediate refresh when returning.
      final pending = Completer<BgmCollectionSyncStatusItem>();
      repo.loader = () => pending.future;
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      final inFlight = repo.reads;
      router.pop();
      await tester.pumpAndSettle();
      pending.complete(waiting);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(repo.reads, inFlight);
      expect(repo.starts, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      c.dispose();
    });
  }
}

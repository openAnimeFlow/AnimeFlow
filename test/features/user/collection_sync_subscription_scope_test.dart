import 'package:anime_flow/features/user/application/bgm_collection_sync_provider.dart';
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
        'subscribes only on $accountPath and cancels on exit without reconnecting',
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
      expect(repo.streams.length, 1);
      repo.streams.last.add(waiting);
      await tester.pump();
      final entered = repo.reads;
      await tester.pump(const Duration(seconds: 30));
      expect(repo.reads, entered); // State arrives via events, not GET polling.
      unawaited(router.push('/other'));
      await tester.pumpAndSettle();
      expect(repo.cancellations.last.isCancelled, isTrue);
      await tester.pump(const Duration(seconds: 90));
      expect(repo.streams.length, 1);
      router.pop();
      await tester.pumpAndSettle();
      expect(repo.streams.length, 2);
      repo.streams.last.add(waiting);
      await tester.pump();
      final notifier = c.read(bgmCollectionSyncProvider.notifier);
      notifier.setForeground(false);
      await tester.pump(const Duration(seconds: 90));
      expect(repo.streams.length, 2);
      expect(repo.cancellations.last.isCancelled, isTrue);
      notifier.setForeground(true);
      await tester.pump();
      expect(repo.streams.length, 3);
      // Connection failure retries, but an intentional exit must cancel the retry.
      repo.streams.last.addError(StateError('disconnected'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(repo.streams.length, 4);
      repo.streams.last.add(null); // heartbeat
      await tester.pump();
      await tester.pump(const Duration(seconds: 50));
      repo.streams.last.add(null);
      await tester.pump();
      await tester.pump(const Duration(seconds: 50));
      expect(repo.streams.length, 4);
      await tester
          .pump(const Duration(seconds: 10)); // silent connection expires
      expect(repo.cancellations.last.isCancelled, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(repo.streams.length, 5);
      repo.streams.last.add(const BgmCollectionSyncStatusItem(
          status: BgmCollectionSyncStatus.waitingConflict,
          taskId: 1,
          statusVersion: 3,
          pendingConflictCount: 2));
      await tester.pump();
      repo.streams.last.add(const BgmCollectionSyncStatusItem(
          status: BgmCollectionSyncStatus.running,
          taskId: 1,
          statusVersion: 2));
      await tester.pump();
      repo.streams.last.add(const BgmCollectionSyncStatusItem(
          status: BgmCollectionSyncStatus.idle));
      await tester.pump();
      expect(c.read(bgmCollectionSyncProvider).value?.statusVersion, 3);
      final pending = Completer<BgmCollectionSyncStatusItem>();
      repo.loader = () => pending.future;
      final refresh = notifier.refreshStatus();
      await tester.pump();
      final inFlight = repo.reads;
      repo.streams.last.addError(StateError('retry pending'));
      await tester.pump();
      router.pop();
      await tester.pumpAndSettle();
      pending.complete(waiting);
      await refresh;
      await tester.pump(const Duration(seconds: 90));
      expect(repo.reads, inFlight);
      expect(repo.streams.length, 5);
      expect(repo.starts, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      c.dispose();
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_flow/features/user/application/collection_sync_lifecycle.dart';
import 'package:anime_flow/features/user/application/bgm_collection_sync_provider.dart';
import 'package:anime_flow/features/user/data/repository/collection_sync_repository.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/shared/models/flow/bangumi_bind_item.dart';
import 'bgm_collection_sync_provider_test.dart' show Token, Profile, Repository;

void main() {
  testWidgets(
      'cold start and resume discover tasks without opening settings or starting sync',
      (tester) async {
    final repo = Repository();
    final c = ProviderContainer(overrides: [
      currentFlowTokenProvider.overrideWith(Token.new),
      currentUserInfoProvider.overrideWith(Profile.new),
      bangumiBindProvider.overrideWith(
          (ref) async => const BangumiBindItem(bound: true, platformUid: 1)),
      collectionSyncRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          home: CollectionSyncLifecycle(child: SizedBox()),
        )));
    await tester.pumpAndSettle();
    await c.read(bgmCollectionSyncProvider.future);
    expect(repo.reads, 1);
    expect(repo.starts, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.reads, 2);
    expect(repo.starts, 0);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/shared/models/flow/bangumi_bind_item.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/features/user/application/bgm_collection_sync_provider.dart';
import 'package:anime_flow/features/user/application/collection_revision_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/features/user/data/repository/collection_sync_repository.dart';

final session = Provider<String>((ref) => 'first');

class Token extends CurrentFlowToken {
  @override
  Future<FlowToken?> build() async => FlowToken(
      accessToken: '',
      refreshToken: '',
      tokenType: '',
      expiresIn: 1,
      refreshExpiresIn: 1,
      sessionId: ref.watch(session));
}

class Profile extends CurrentUserInfo {
  @override
  Future<FlowUsers?> build() async => null;
}

class Repository extends CollectionSyncRepository {
  int reads = 0, starts = 0;
  Future<BgmCollectionSyncStatusItem> Function()? loader;
  @override
  Future<BgmCollectionSyncStatusItem> status() async {
    reads++;
    return loader == null
        ? const BgmCollectionSyncStatusItem(
            status: BgmCollectionSyncStatus.idle)
        : await loader!();
  }

  @override
  Future<BgmCollectionSyncStatusItem> trigger(int type, String key) async {
    starts++;
    return const BgmCollectionSyncStatusItem(
        status: BgmCollectionSyncStatus.queued);
  }
}

void main() {
  ProviderContainer create(Repository repository) =>
      ProviderContainer(overrides: [
        currentFlowTokenProvider.overrideWith(Token.new),
        currentUserInfoProvider.overrideWith(Profile.new),
        bangumiBindProvider.overrideWith(
            (ref) async => const BangumiBindItem(bound: true, platformUid: 1)),
        collectionSyncRepositoryProvider.overrideWithValue(repository),
      ]);

  test('discovery only reads status and merges overlapping refreshes',
      () async {
    final repo = Repository();
    final c = create(repo);
    addTearDown(c.dispose);
    await c.read(bgmCollectionSyncProvider.future);
    final pending = Completer<BgmCollectionSyncStatusItem>();
    repo.loader = () => pending.future;
    final notifier = c.read(bgmCollectionSyncProvider.notifier);
    final a = notifier.refreshStatus(), b = notifier.refreshStatus();
    await Future<void>.delayed(Duration.zero);
    expect(repo.reads, 2);
    expect(repo.starts, 0);
    pending.complete(const BgmCollectionSyncStatusItem(
        status: BgmCollectionSyncStatus.idle));
    await Future.wait([a, b]);
  });

  test('old in-flight refresh cannot overwrite a rebuilt session', () async {
    final repo = Repository();
    final c = create(repo);
    addTearDown(c.dispose);
    await c.read(bgmCollectionSyncProvider.future);
    final old = Completer<BgmCollectionSyncStatusItem>();
    repo.loader = () => old.future;
    final pending = c.read(bgmCollectionSyncProvider.notifier).refreshStatus();
    await Future<void>.delayed(Duration.zero);
    repo.loader = () async => const BgmCollectionSyncStatusItem(
        status: BgmCollectionSyncStatus.idle, userId: 2);
    c.invalidate(bgmCollectionSyncProvider);
    await c.read(bgmCollectionSyncProvider.future);
    old.complete(const BgmCollectionSyncStatusItem(
        status: BgmCollectionSyncStatus.waitingConflict,
        userId: 1,
        pendingConflictCount: 5));
    await pending;
    expect(c.read(bgmCollectionSyncProvider).value?.userId, 2);
    expect(c.read(bgmCollectionSyncProvider).value?.pendingConflictCount, 0);
  });

  test('completed progress invalidates detail revision only when changed',
      () async {
    final repo = Repository();
    final c = create(repo);
    addTearDown(c.dispose);
    await c.read(bgmCollectionSyncProvider.future);
    repo.loader = () async => const BgmCollectionSyncStatusItem(
        status: BgmCollectionSyncStatus.success, taskId: 1, syncedCount: 5);
    await c.read(bgmCollectionSyncProvider.notifier).refreshStatus();
    expect(c.read(collectionRevisionProvider), 1);
    await c.read(bgmCollectionSyncProvider.notifier).refreshStatus();
    expect(c.read(collectionRevisionProvider), 1);
  });
}

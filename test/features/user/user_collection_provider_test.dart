import 'package:anime_flow/shared/models/flow/collection_update_result.dart';
import 'dart:async';

import 'package:anime_flow/features/user/presentation/providers/user_collection_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_collection_state.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

UserCollectionData _item(int type) => UserCollectionData.fromJson({
      'id': 42,
      'name': 'Example',
      'type': 2,
      'rating': <String, dynamic>{},
      'images': <String, dynamic>{},
      'interest': {'id': 1, 'type': type, 'updatedAt': 1},
    });

class _Collections extends UserCollections {
  @override
  UserCollectionsState build() => UserCollectionsState(tabs: {
        1: UserCollectionTabState(
          data: UserCollectionsItem(data: [_item(1)], total: 1),
          offset: 1,
          hasMore: false,
        ),
      });
}

class _UserInfo extends CurrentUserInfo {
  @override
  Future<FlowUsers?> build() async => null;
}

void main() {
  test('pending remote upload still moves local collection and returns status',
      () async {
    final container = ProviderContainer(overrides: [
      userCollectionsProvider.overrideWith(_Collections.new),
      currentUserInfoProvider.overrideWith(_UserInfo.new),
      collectionTypeUpdateProvider.overrideWithValue((_, __) async =>
          const CollectionUpdateResult(
              remoteSyncStatus: CollectionRemoteSyncStatus.pending)),
    ]);
    addTearDown(container.dispose);
    await container.read(currentUserInfoProvider.future);
    final result = await container
        .read(userCollectionsProvider.notifier)
        .updateCollectionType(_item(1), 3);
    expect(result!.remoteSyncStatus, CollectionRemoteSyncStatus.pending);
    final state = container.read(userCollectionsProvider);
    expect(state.tabState(1).data!.data, isEmpty);
    expect(state.tabState(3).data!.data.single.interest.remoteSyncStatus,
        'PENDING');
  });

  test('saving the same category retries without changing collection counts',
      () async {
    var saves = 0;
    final container = ProviderContainer(overrides: [
      userCollectionsProvider.overrideWith(_Collections.new),
      collectionTypeUpdateProvider.overrideWithValue((_, __) async {
        saves++;
        return const CollectionUpdateResult(
            remoteSyncStatus: CollectionRemoteSyncStatus.synced);
      }),
      collectionPageLoaderProvider.overrideWithValue(
        ({required type, required offset, keyword}) async =>
            UserCollectionsItem(data: [_item(1)], total: 1),
      ),
    ]);
    addTearDown(container.dispose);
    await container
        .read(userCollectionsProvider.notifier)
        .updateCollectionType(_item(1), 1);
    expect(saves, 1);
    expect(container.read(userCollectionsProvider).tabState(1).data!.total, 1);
  });

  for (final failOldRequest in [false, true]) {
    test('reset ignores old request (failure: $failOldRequest)', () async {
      final oldPage = Completer<UserCollectionsItem>();
      final newPage = Completer<UserCollectionsItem>();
      var requests = 0;
      final container = ProviderContainer(overrides: [
        collectionPageLoaderProvider.overrideWithValue(
          ({required type, required offset, keyword}) =>
              requests++ == 0 ? oldPage.future : newPage.future,
        ),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(userCollectionsProvider.notifier);
      final oldRequest = notifier.loadInitial(1);
      notifier.reset();
      final newRequest = notifier.loadInitial(1);
      if (failOldRequest) {
        oldPage.completeError(StateError('Old session failed'));
      } else {
        oldPage.complete(UserCollectionsItem(data: [_item(1)], total: 1));
      }
      await oldRequest;
      final pending = container.read(userCollectionsProvider).tabState(1);
      expect(pending.data, isNull);
      expect(pending.initialErrorMessage, isNull);
      expect(pending.isInitialLoading, isTrue);
      newPage.complete(UserCollectionsItem(data: [], total: 0));
      await newRequest;
      expect(
          container.read(userCollectionsProvider).tabState(1).isBusy, isFalse);
      expect(container.read(userCollectionsProvider).tabState(1).data!.data,
          isEmpty);
    });
  }

  test('disposed provider ignores a pending page', () async {
    final page = Completer<UserCollectionsItem>();
    final container = ProviderContainer(overrides: [
      collectionPageLoaderProvider.overrideWithValue(
        ({required type, required offset, keyword}) => page.future,
      ),
    ]);
    final request =
        container.read(userCollectionsProvider.notifier).loadInitial(1);
    container.dispose();
    page.complete(UserCollectionsItem(data: [], total: 0));
    await expectLater(request, completes);
  });

  test('reset ignores a pending collection update', () async {
    final update = Completer<CollectionUpdateResult>();
    final container = ProviderContainer(overrides: [
      userCollectionsProvider.overrideWith(_Collections.new),
      collectionTypeUpdateProvider.overrideWithValue((_, __) => update.future),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(userCollectionsProvider.notifier);
    final request = notifier.updateCollectionType(_item(1), 3);
    notifier.reset();
    update.complete(const CollectionUpdateResult(
        remoteSyncStatus: CollectionRemoteSyncStatus.localOnly));
    await request;
    expect(container.read(userCollectionsProvider).tabs, isEmpty);
  });

  test('fresh detail state submits even when cached type equals target',
      () async {
    final requests = <(int, int)>[];
    final container = ProviderContainer(overrides: [
      userCollectionsProvider.overrideWith(_Collections.new),
      currentUserInfoProvider.overrideWith(_UserInfo.new),
      collectionTypeUpdateProvider
          .overrideWithValue((collection, newType) async {
        requests.add((collection.interest.type, newType));
        return const CollectionUpdateResult(
            remoteSyncStatus: CollectionRemoteSyncStatus.localOnly);
      }),
    ]);
    addTearDown(container.dispose);
    await container.read(currentUserInfoProvider.future);
    final notifier = container.read(userCollectionsProvider.notifier);
    await notifier.updateCollectionType(_item(3), 1);
    expect(requests, [(3, 1)]);
    expect(
        container.read(userCollectionsProvider).tabState(1).data!.data.length,
        1);
    expect(container.read(userCollectionsProvider).tabState(1).data!.total, 1);
  });

  test('failed detail update preserves cached collection data', () async {
    var requests = 0;
    final container = ProviderContainer(overrides: [
      userCollectionsProvider.overrideWith(_Collections.new),
      collectionTypeUpdateProvider
          .overrideWithValue((collection, newType) async {
        requests++;
        throw StateError('Update failed');
      }),
    ]);
    addTearDown(container.dispose);
    final before = container.read(userCollectionsProvider);
    await expectLater(
      container
          .read(userCollectionsProvider.notifier)
          .updateCollectionType(_item(3), 1),
      throwsStateError,
    );
    expect(requests, 1);
    expect(container.read(userCollectionsProvider), same(before));
  });
}

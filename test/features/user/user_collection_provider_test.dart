import 'package:anime_flow/shared/models/flow/collection_update_result.dart';
import 'dart:async';
import 'dart:io';

import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/user/application/user_collection_provider.dart';
import 'package:anime_flow/features/user/application/user_collection_state.dart';
import 'package:anime_flow/features/user/application/user_state_provider.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/user/application/collection_revision_provider.dart';
import 'package:anime_flow/features/user/application/collection_refresh_provider.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:anime_flow/shared/models/enums/collection_sort.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

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
  late Directory settingsDirectory;
  setUpAll(() async {
    settingsDirectory =
        await Directory.systemTemp.createTemp('collection_sort_test_');
    Hive.init(settingsDirectory.path);
    Storage.setting = await Hive.openBox<dynamic>('collection_sort_settings');
  });
  setUp(() => Storage.setting.clear());
  tearDownAll(() async {
    await Hive.close();
    await settingsDirectory.delete(recursive: true);
  });

  for (final sessionChange in [true, false]) {
    for (final fail in [true, false]) {
      test(
          'revision reset discards pending page: session=$sessionChange error=$fail',
          () async {
        final page = Completer<UserCollectionsItem>();
        final container = ProviderContainer(overrides: [
          collectionPageLoaderProvider.overrideWithValue((
                  {required type, required offset, required sort, keyword}) =>
              page.future),
        ]);
        addTearDown(container.dispose);
        final pending =
            container.read(userCollectionsProvider.notifier).loadInitial(1);
        if (sessionChange) {
          container.read(authSessionRevisionProvider.notifier).changed();
        } else {
          container.read(collectionRefreshProvider.notifier).changed();
        }
        expect(container.read(userCollectionsProvider).tabs, isEmpty);
        if (fail) {
          page.completeError(StateError('Old response'));
        } else {
          page.complete(UserCollectionsItem(data: [_item(1)], total: 1));
        }
        await pending;
        expect(container.read(userCollectionsProvider).tabs, isEmpty);
      });
    }
  }

  test('cache eviction signal preserves optimistic collection pages', () async {
    final container = ProviderContainer(overrides: [
      collectionPageLoaderProvider.overrideWithValue((
              {required type, required offset, required sort, keyword}) async =>
          UserCollectionsItem(data: [_item(1)], total: 1)),
    ]);
    addTearDown(container.dispose);
    await container.read(userCollectionsProvider.notifier).loadInitial(1);
    final pages = container.read(userCollectionsProvider);
    container.read(collectionRevisionProvider.notifier).changed();
    expect(container.read(userCollectionsProvider), same(pages));
  });

  test('saved sort is restored per category by a new provider and after reset',
      () async {
    final requests = <(int, String?, CollectionSort)>[];
    Future<UserCollectionsItem> load({
      required int type,
      required int offset,
      required CollectionSort sort,
      String? keyword,
    }) async {
      requests.add((type, keyword, sort));
      return UserCollectionsItem(data: [], total: 0);
    }

    final original = ProviderContainer(overrides: [
      collectionPageLoaderProvider.overrideWithValue(load),
    ]);
    final notifier = original.read(userCollectionsProvider.notifier);
    await notifier.applyFilters(1,
        keyword: 'Example', sort: CollectionSort.defaultSort);
    await notifier.applyFilters(3, keyword: '', sort: CollectionSort.watch);
    await notifier.applyFilters(5, keyword: '', sort: CollectionSort.watch);
    await Storage.setting.flush();
    expect(Storage.setting.get('${SettingKey.collectionSort}_1'), 'default');
    expect(Storage.setting.get('${SettingKey.collectionSort}_3'), 'watch');
    expect(Storage.setting.get('${SettingKey.collectionSort}_5'), 'watch');
    original.dispose();

    requests.clear();
    final restarted = ProviderContainer(overrides: [
      collectionPageLoaderProvider.overrideWithValue(load),
    ]);
    addTearDown(restarted.dispose);
    final restored = restarted.read(userCollectionsProvider.notifier);
    await restored.loadInitial(1);
    await restored.loadInitial(3);
    await restored.loadInitial(5);
    expect(requests, [
      (1, null, CollectionSort.defaultSort),
      (3, null, CollectionSort.watch),
      (5, null, CollectionSort.watch),
    ]);
    expect(restarted.read(userCollectionsProvider).tabState(3).sort,
        CollectionSort.watch);

    restored.reset();
    await restored.loadInitial(3);
    expect(requests.last, (3, null, CollectionSort.watch));
    await restored.applyFilters(3,
        keyword: '', sort: CollectionSort.defaultSort);
    expect(AppSettings.getCollectionSort(3), CollectionSort.defaultSort);
    expect(AppSettings.getCollectionSort(5), CollectionSort.watch);
  });

  test('missing or invalid saved sorts fall back to default', () async {
    expect(AppSettings.getCollectionSort(1), CollectionSort.defaultSort);
    await Storage.setting.put('${SettingKey.collectionSort}_2', 'unknown');
    await Storage.setting.put('${SettingKey.collectionSort}_3', 1);
    expect(AppSettings.getCollectionSort(2), CollectionSort.defaultSort);
    expect(AppSettings.getCollectionSort(3), CollectionSort.defaultSort);
  });

  test('filters are retained for pagination, refresh and each category',
      () async {
    final requests = <(int, int, String?, CollectionSort)>[];
    final container = ProviderContainer(overrides: [
      collectionPageLoaderProvider.overrideWithValue(
        ({required type, required offset, required sort, keyword}) async {
          requests.add((type, offset, keyword, sort));
          return UserCollectionsItem(
            data: List.generate(20, (index) {
              final json = _item(type).toJson();
              json['id'] = offset + index;
              return UserCollectionData.fromJson(json);
            }),
            total: 40,
          );
        },
      ),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(userCollectionsProvider.notifier);

    await notifier.applyFilters(3,
        keyword: ' Example ', sort: CollectionSort.watch);
    await notifier.loadMore(3);
    await notifier.refresh(3);
    await notifier.loadInitial(1);

    expect(requests, [
      (3, 0, 'Example', CollectionSort.watch),
      (3, 20, 'Example', CollectionSort.watch),
      (3, 0, 'Example', CollectionSort.watch),
      (1, 0, null, CollectionSort.defaultSort),
    ]);
    expect(container.read(userCollectionsProvider).tabState(3).sort,
        CollectionSort.watch);

    await notifier.applyFilters(3, keyword: '', sort: CollectionSort.watch);
    expect(requests.last, (3, 0, null, CollectionSort.watch));
    await notifier.applyFilters(3,
        keyword: '', sort: CollectionSort.defaultSort);
    expect(requests.last, (3, 0, null, CollectionSort.defaultSort));
    expect(container.read(userCollectionsProvider).tabState(3).keyword, isNull);
    expect(container.read(userCollectionsProvider).tabState(1).offset, 20);
  });

  test('changing sort discards a pending page from the previous filters',
      () async {
    final oldPage = Completer<UserCollectionsItem>();
    final newPage = Completer<UserCollectionsItem>();
    final newRequestStarted = Completer<void>();
    final container = ProviderContainer(overrides: [
      collectionPageLoaderProvider.overrideWithValue(
        ({required type, required offset, required sort, keyword}) {
          if (sort == CollectionSort.watch) {
            newRequestStarted.complete();
            return newPage.future;
          }
          return oldPage.future;
        },
      ),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(userCollectionsProvider.notifier);
    final oldRequest = notifier.loadInitial(3);
    final newRequest =
        notifier.applyFilters(3, keyword: 'new', sort: CollectionSort.watch);
    await newRequestStarted.future;

    oldPage.complete(UserCollectionsItem(data: [_item(3)], total: 1));
    await oldRequest;
    final pending = container.read(userCollectionsProvider).tabState(3);
    expect(pending.data, isNull);
    expect(pending.isInitialLoading, isTrue);
    expect(pending.sort, CollectionSort.watch);
    expect(pending.keyword, 'new');

    newPage.complete(UserCollectionsItem(data: [], total: 0));
    await newRequest;
    expect(container.read(userCollectionsProvider).tabState(3).data!.data,
        isEmpty);
    expect(container.read(userCollectionsProvider).tabState(3).isBusy, isFalse);
  });

  test('cancelling uses DELETE path and removes the local collection',
      () async {
    final cancelledIds = <int>[];
    final container = ProviderContainer(overrides: [
      userCollectionsProvider.overrideWith(_Collections.new),
      currentUserInfoProvider.overrideWith(_UserInfo.new),
      collectionCancelProvider.overrideWithValue((subjectId) async {
        cancelledIds.add(subjectId);
      }),
      collectionTypeUpdateProvider.overrideWithValue((_, __) async {
        throw StateError('PUT must not be used for cancellation');
      }),
    ]);
    addTearDown(container.dispose);
    await container.read(currentUserInfoProvider.future);

    final result = await container
        .read(userCollectionsProvider.notifier)
        .updateCollectionType(_item(1), 0);

    expect(result, isNull);
    expect(cancelledIds, [42]);
    final state = container.read(userCollectionsProvider);
    expect(state.tabState(1).data!.data, isEmpty);
    expect(state.tabState(1).data!.total, 0);
    expect(state.tabs.containsKey(0), isFalse);
  });

  test('failed cancellation leaves the collection visible', () async {
    final container = ProviderContainer(overrides: [
      userCollectionsProvider.overrideWith(_Collections.new),
      collectionCancelProvider.overrideWithValue((_) async {
        throw StateError('DELETE failed');
      }),
    ]);
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(userCollectionsProvider.notifier)
          .updateCollectionType(_item(1), 0),
      throwsStateError,
    );
    expect(container.read(userCollectionsProvider).tabState(1).data!.data,
        hasLength(1));
  });

  test('cancellation removes stale cached category from a newer detail state',
      () async {
    final container = ProviderContainer(overrides: [
      userCollectionsProvider.overrideWith(_Collections.new),
      collectionCancelProvider.overrideWithValue((_) async {}),
    ]);
    addTearDown(container.dispose);

    await container
        .read(userCollectionsProvider.notifier)
        .updateCollectionType(_item(3), 0);

    expect(container.read(userCollectionsProvider).tabState(1).data!.data,
        isEmpty);
    expect(container.read(userCollectionsProvider).tabState(1).data!.total, 0);
  });

  test('cancellation restarts an in-flight page to avoid stale results',
      () async {
    final oldPage = Completer<UserCollectionsItem>();
    var requests = 0;
    final container = ProviderContainer(overrides: [
      userCollectionsProvider.overrideWith(_Collections.new),
      collectionCancelProvider.overrideWithValue((_) async {}),
      collectionPageLoaderProvider.overrideWithValue(
        ({required type, required offset, required sort, keyword}) {
          requests++;
          return requests == 1
              ? oldPage.future
              : Future.value(UserCollectionsItem(data: [], total: 0));
        },
      ),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(userCollectionsProvider.notifier);
    final originalLoad = notifier.loadInitial(2);

    await notifier.updateCollectionType(_item(1), 0);
    await Future<void>.delayed(Duration.zero);
    oldPage.complete(UserCollectionsItem(data: [_item(1)], total: 1));
    await originalLoad;

    expect(requests, 2);
    expect(container.read(userCollectionsProvider).tabState(2).data!.data,
        isEmpty);
  });

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
        ({required type, required offset, required sort, keyword}) async =>
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
          ({required type, required offset, required sort, keyword}) =>
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
        ({required type, required offset, required sort, keyword}) =>
            page.future,
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

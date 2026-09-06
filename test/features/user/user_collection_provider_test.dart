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
  test('fresh detail state submits even when cached type equals target',
      () async {
    final requests = <(int, int)>[];
    final container = ProviderContainer(overrides: [
      userCollectionsProvider.overrideWith(_Collections.new),
      currentUserInfoProvider.overrideWith(_UserInfo.new),
      collectionTypeUpdateProvider
          .overrideWithValue((collection, newType) async {
        requests.add((collection.interest.type, newType));
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

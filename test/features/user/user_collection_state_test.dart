import 'package:anime_flow/features/user/presentation/providers/user_collection_state.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:flutter_test/flutter_test.dart';

UserCollectionData collection(int id, int type) => UserCollectionData.fromJson({
      'id': id,
      'name': 'Anime $id',
      'nameCN': '动画 $id',
      'type': 2,
      'rating': <String, dynamic>{},
      'images': <String, dynamic>{},
      'interest': {
        'id': id,
        'type': type,
        'rate': 8,
        'comment': 'Keep this',
        'updatedAt': 1,
      },
    });

void main() {
  test('first collection creates only the destination category', () {
    final result = const UserCollectionsState()
        .moveCollection(collection(1, 0), 3, destinationTotal: 1);
    expect(result.tabs.keys, [3]);
    expect(result.tabState(3).data!.data.single.interest.type, 3);
    expect(result.tabState(3).data!.total, 1);
  });

  test('successive moves use the latest collection type', () {
    final first = const UserCollectionsState()
        .moveCollection(collection(1, 0), 3, destinationTotal: 1);
    final second = first.moveCollection(
      first.tabState(3).data!.data.single,
      2,
      destinationTotal: 1,
    );
    expect(second.tabState(3).data!.total, 0);
    expect(second.tabState(3).data!.data, isEmpty);
    expect(second.tabState(2).data!.total, 1);
    expect(second.tabState(2).data!.data.single.interest.type, 2);
    expect(second.tabs.containsKey(0), isFalse);
  });

  test('moving a collection adjusts cached pages and rejects stale requests',
      () {
    final item = collection(1, 1);
    final state = UserCollectionsState(tabs: {
      1: UserCollectionTabState(
        data: UserCollectionsItem(data: [item], total: 21),
        offset: 1,
        hasMore: true,
        isLoadingMore: true,
      ),
      2: UserCollectionTabState(
        data: UserCollectionsItem(data: [collection(2, 2)], total: 1),
        offset: 1,
        hasMore: false,
      ),
    });
    final result = state.moveCollection(item, 2, destinationTotal: 2);
    expect(result.tabState(1).data!.data, isEmpty);
    expect(result.tabState(1).data!.total, 20);
    expect(result.tabState(1).offset, 0);
    expect(result.tabState(1).hasMore, isTrue);
    expect(result.tabState(1).isLoadingMore, isFalse);
    expect(result.tabState(1).requestVersion, 1);
    final target = result.tabState(2);
    expect(target.data!.data.map((e) => e.id), [1, 2]);
    expect(target.offset, 2);
    expect(target.data!.total, 2);
    expect(target.hasMore, isFalse);
    expect(target.data!.data.first.interest.type, 2);
    expect(target.data!.data.first.interest.rate, 8);
    expect(item.interest.type, 1);
  });

  test('a nonmatching destination search does not receive the item', () {
    final state = UserCollectionsState(tabs: {
      2: UserCollectionTabState(
        data: UserCollectionsItem(data: [], total: 0),
        keyword: 'unrelated',
        hasMore: false,
      ),
    });
    final target = state
        .moveCollection(collection(1, 1), 2, destinationTotal: 10)
        .tabState(2);
    expect(target.data!.data, isEmpty);
    expect(target.data!.total, 0);
    expect(target.offset, 0);
    expect(target.keyword, 'unrelated');
  });

  test('an uncached destination remains pageable after local insertion', () {
    final target = const UserCollectionsState()
        .moveCollection(collection(1, 1), 2, destinationTotal: 31)
        .tabState(2);
    expect(target.data!.data.single.id, 1);
    expect(target.data!.total, 31);
    expect(target.offset, 1);
    expect(target.canLoadMore, isTrue);
  });
}

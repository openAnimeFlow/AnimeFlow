import 'package:anime_flow/models/item/bangumi/image_five_item.dart';
import 'package:anime_flow/models/item/bangumi/rating_item.dart';
import 'package:anime_flow/models/item/bangumi/user_collections_item.dart';
import 'package:anime_flow/pages/user/service/user_collection_service.dart';
import 'package:flutter_test/flutter_test.dart';

UserCollectionData _item(int id) {
  return UserCollectionData(
    id: id,
    name: 'item$id',
    type: 2,
    info: '',
    rating: RatingItem(rank: 0, count: const [], score: 0, total: 0),
    locked: false,
    nsfw: false,
    images: ImageFiveItem.empty,
    interest: UserCollectionInterest(
      id: id,
      rate: 0,
      type: 1,
      comment: '',
      tags: const [],
      updatedAt: 0,
    ),
  );
}

UserCollectionsItem _page({
  required int count,
  required int total,
  int startId = 0,
}) {
  return UserCollectionsItem(
    data: List.generate(count, (index) => _item(startId + index)),
    total: total,
  );
}

void main() {
  group('UserCollectionService', () {
    final service = UserCollectionService();

    test('mergeLoadMore appends items and updates total', () {
      final cached = _page(count: 20, total: 45, startId: 0);
      final page = _page(count: 20, total: 45, startId: 20);

      final merged = service.mergeLoadMore(cached: cached, page: page);

      expect(merged.data.length, 40);
      expect(merged.data.last.id, 39);
      expect(merged.total, 45);
    });

    test('hasMoreAfterFetch is true when page is full and below total', () {
      final page = _page(count: UserCollectionService.pageSize, total: 45);

      expect(
        service.hasMoreAfterFetch(page: page, loadedCount: 20),
        isTrue,
      );
    });

    test('hasMoreAfterFetch is false when loaded count reaches total', () {
      final page = _page(count: 5, total: 25);

      expect(
        service.hasMoreAfterFetch(page: page, loadedCount: 25),
        isFalse,
      );
    });
  });
}

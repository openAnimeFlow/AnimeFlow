import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/pages/play/service/episodes_pagination.dart';
import 'package:flutter_test/flutter_test.dart';

EpisodeData _episode(int id, {num sort = 1}) {
  return EpisodeData(
    id: id,
    subjectID: 1,
    sort: sort,
    type: 0,
    disc: 0,
    name: 'ep$id',
    nameCN: '',
    duration: '',
    airdate: '',
    comment: 0,
    desc: '',
  );
}

void main() {
  group('EpisodesPagination', () {
    test('mergePages appends data and keeps total from latest page', () {
      final cached = EpisodesItem(
        data: [_episode(1), _episode(2)],
        total: 5,
      );
      final page = EpisodesItem(
        data: [_episode(3), _episode(4)],
        total: 5,
      );

      final merged = EpisodesPagination.mergePages(cached: cached, page: page);

      expect(merged.data.length, 4);
      expect(merged.data.last.id, 4);
      expect(merged.total, 5);
    });

    test('hasMore is true when loaded count is less than total', () {
      final item = EpisodesItem(
        data: List.generate(100, (i) => _episode(i)),
        total: 250,
      );

      expect(EpisodesPagination.hasMore(item), isTrue);
    });

    test('hasMore is false when all episodes are loaded', () {
      final item = EpisodesItem(
        data: List.generate(3, (i) => _episode(i)),
        total: 3,
      );

      expect(EpisodesPagination.hasMore(item), isFalse);
    });
  });
}

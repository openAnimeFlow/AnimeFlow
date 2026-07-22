import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/providers/episodes/subject_episodes_provider.dart';
import 'package:flutter_test/flutter_test.dart';

EpisodeData _episode(int id, {num sort = 1, int type = 0, bool? watched}) {
  return EpisodeData(
    id: id,
    subjectID: 1,
    sort: sort,
    type: type,
    disc: 0,
    name: 'ep$id',
    nameCN: '',
    duration: '',
    airdate: '',
    comment: 0,
    desc: '',
    watched: watched,
  );
}

void main() {
  group('SubjectEpisodesState pagination', () {
    test('orders main episodes before special episodes', () {
      final state = SubjectEpisodesState(
        episodes: EpisodesItem(
          data: [
            _episode(101, sort: 1, type: 3),
            _episode(2, sort: 2),
            _episode(1, sort: 1),
            _episode(102, sort: 2, type: 3),
          ],
          total: 4,
        ),
      );

      expect(
        state.episodes.data.map((episode) => episode.id),
        [1, 2, 101, 102],
      );
    });

    test('hasMore is true when loaded count is less than total', () {
      final item = EpisodesItem(
        data: List.generate(100, (i) => _episode(i)),
        total: 250,
      );

      expect(SubjectEpisodesState(episodes: item).hasMore, isTrue);
    });

    test('hasMore is false when all episodes are loaded', () {
      final item = EpisodesItem(
        data: List.generate(3, (i) => _episode(i)),
        total: 3,
      );

      expect(SubjectEpisodesState(episodes: item).hasMore, isFalse);
    });
  });

  group('SubjectEpisodesState initial selection', () {
    test('selects the episode after the last watched episode by default', () {
      final state = SubjectEpisodesState(
        episodes: EpisodesItem(
          data: [
            _episode(1, watched: true),
            _episode(2, watched: true),
            _episode(3),
          ],
          total: 3,
        ),
      );

      final selection = state.selectionForContinueEpisode();

      expect(selection?.id, 3);
      expect(selection?.index, 3);
    });

    test('uses the sorted playback order for watched continuation', () {
      final state = SubjectEpisodesState(
        episodes: EpisodesItem(
          data: [
            _episode(101, sort: 1, type: 3),
            _episode(102, sort: 2, type: 3),
            _episode(1, sort: 1, watched: true),
            _episode(2, sort: 2, watched: true),
            _episode(3, sort: 3),
          ],
          total: 5,
        ),
      );

      final selection = state.selectionForContinueEpisode();

      expect(selection?.id, 3);
      expect(selection?.index, 3);
    });

    test('finds an episode by id when episode sort does not start from one',
        () {
      final state = SubjectEpisodesState(
        episodes: EpisodesItem(
          data: [
            _episode(500, sort: 50),
            _episode(501, sort: 51),
            _episode(502, sort: 52),
          ],
          total: 3,
        ),
      );

      final selection = state.findSelectionById(501);

      expect(selection?.id, 501);
      expect(selection?.sort, 51);
      expect(selection?.index, 2);
    });

    test('uses the requested episode id when one is supplied', () {
      final state = SubjectEpisodesState(
        episodes: EpisodesItem(
          data: [
            _episode(1, sort: 1, watched: true),
            _episode(2, sort: 2),
            _episode(3, sort: 3),
          ],
          total: 3,
        ),
      );

      final selection = state.findSelectionById(2);

      expect(selection?.id, 2);
      expect(selection?.index, 2);
    });

    test('falls back to the first episode when there is no watched episode',
        () {
      final state = SubjectEpisodesState(
        episodes: EpisodesItem(
          data: [
            _episode(1),
            _episode(2),
          ],
          total: 2,
        ),
      );

      final selection = state.selectionForContinueEpisode();

      expect(selection?.id, 1);
      expect(selection?.index, 1);
    });
  });
}

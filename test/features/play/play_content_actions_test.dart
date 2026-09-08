import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/play/presentation/providers/play_content_actions.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

EpisodeData _episode(int id, int sort) => EpisodeData(
      id: id,
      subjectID: 1,
      sort: sort,
      type: 0,
      disc: 0,
      name: 'Episode $id',
      nameCN: '',
      duration: '',
      airdate: '',
      comment: 0,
      desc: '',
    );

class _Episodes extends Episodes {
  @override
  Future<EpisodesData> build() async => EpisodesData(
        subjectId: 1,
        episodes:
            EpisodesItem(data: [_episode(10, 50), _episode(20, 51)], total: 2),
        episodeId: 10,
        episodeIndex: 1,
        episodeSort: 50,
        episodeTitle: 'Episode 10',
      );
}

class _Session implements PlaySession {
  int resumed = 0;
  @override
  Future<void> startPlaying() async {
    resumed++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;
  late ProviderContainer root;
  late _Session session;
  setUp(() {
    root = ProviderContainer();
    session = _Session();
    container = ProviderContainer(parent: root, overrides: [
      playExtraProvider.overrideWithValue(const PlayRouteExtra(
        isOfflineMode: true,
        playExtra: PlayExtra(
            subjectId: 1,
            subjectName: 'Subject',
            subjectCover: '',
            subjectAliases: []),
      )),
      episodesProvider.overrideWith(_Episodes.new),
      playSessionProvider.overrideWithValue(session),
    ]);
    container.listen(episodesProvider, (_, next) {});
  });
  tearDown(() {
    container.dispose();
    root.dispose();
  });

  test('resume resolves the player session from the route scope', () async {
    await container.read(playContentActionsProvider).resume();
    expect(session.resumed, 1);
  });

  for (final entry in [
    'embedded details',
    'episode selection',
    'next episode'
  ]) {
    test('$entry updates id, playback index, sort and title together',
        () async {
      await container.read(episodesProvider.future);
      final updates = <EpisodesData>[];
      container.listen(episodesProvider, (_, next) {
        if (next.asData != null) updates.add(next.asData!.value);
      });
      switch (entry) {
        case 'embedded details':
          await container.read(playContentActionsProvider).selectEpisode(20);
        case 'episode selection':
          container.read(episodesProvider.notifier).selectEpisode(20);
        case 'next episode':
          container.read(episodesProvider.notifier).switchToNextEpisode();
      }
      expect(updates, hasLength(1));
      expect(updates.single.episodeId, 20);
      expect(updates.single.episodeIndex, 2);
      expect(updates.single.episodeSort, 51);
      expect(updates.single.episodeTitle, 'Episode 20');
    });
  }

  test('reselecting and advancing past the last episode publish no updates',
      () async {
    await container.read(episodesProvider.future);
    final notifier = container.read(episodesProvider.notifier);
    notifier.selectEpisode(20);
    final updates = <EpisodesData>[];
    container.listen(episodesProvider, (_, next) {
      if (next.asData != null) updates.add(next.asData!.value);
    });
    notifier.selectEpisode(20);
    notifier.switchToNextEpisode();
    expect(updates, isEmpty);
  });

  test('selecting the current episode resumes without changing selection',
      () async {
    final before = await container.read(episodesProvider.future);
    final actions = container.read(playContentActionsProvider);
    await actions.selectEpisode(10);
    expect(session.resumed, 1);
    expect(container.read(episodesProvider).asData!.value, same(before));
  });

  test('unavailable offline episode leaves the current session intact',
      () async {
    final before = await container.read(episodesProvider.future);
    await expectLater(
      container.read(playContentActionsProvider).selectEpisode(999),
      throwsStateError,
    );
    expect(container.read(episodesProvider).asData!.value, same(before));
  });
}

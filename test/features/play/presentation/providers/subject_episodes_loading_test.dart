import 'package:anime_flow/features/auth/auth_api.dart';
import 'dart:async';
import 'dart:io';

import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/subject_episodes_provider.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

class _GuestToken extends CurrentFlowToken {
  @override
  Future<FlowToken?> build() async => null;
}

class _Request {
  _Request(this.offset);
  final int offset;
  final result = Completer<EpisodesItem>();
}

class _Episodes extends SubjectEpisodes {
  final requests = <_Request>[];
  final firstRequest = Completer<void>();

  @override
  Future<EpisodesItem> fetchPage(int subjectId, {required int offset}) {
    final request = _Request(offset);
    requests.add(request);
    if (!firstRequest.isCompleted) firstRequest.complete();
    return request.result.future;
  }
}

EpisodesItem _page(List<int> ids, int total) => EpisodesItem(
      total: total,
      data: ids
          .map((id) => EpisodeData.fromJson({
                'id': id,
                'subjectID': 1,
                'sort': id,
                'name': 'Episode $id',
                'type': 0,
                'disc': 0,
                'name_cn': '',
                'duration': '',
                'airdate': '',
                'comment': 0,
                'desc': '',
              }))
          .toList(),
    );

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late Directory directory;
  late ProviderContainer container;
  late _Episodes notifier;
  final provider = subjectEpisodesProvider(1);
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('subject_episodes_test_');
    Hive.init(directory.path);
    Storage.subjectEpisodesCache = await Hive.openBox<String>('episodes');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    await Storage.subjectEpisodesCache.clear();
    notifier = _Episodes();
    container = ProviderContainer(retry: (_, error) => null, overrides: [
      currentFlowTokenProvider.overrideWith(_GuestToken.new),
      provider.overrideWith(() => notifier),
    ]);
    container.listen(provider, (_, next) {});
    // Loading now awaits the session and cache lookup before requesting a page.
    await notifier.firstRequest.future;
  });
  tearDown(() => container.dispose());

  test('target loading waits for initialization and shares concurrent pages',
      () async {
    final target = notifier.loadUntilEpisodeId(3);
    final more = notifier.loadMore();
    expect(notifier.loadMore(), same(more));
    notifier.requests[0].result.complete(_page([1], 3));
    await _flush();
    expect(notifier.requests.map((r) => r.offset), [0, 1]);
    notifier.requests[1].result.complete(_page([2, 3], 3));
    await target;
    expect(await more, isTrue);
    expect(container.read(provider).requireValue.hasMore, isFalse);
  });

  test('page failure stops target loading and explicit retry can succeed',
      () async {
    notifier.requests[0].result.complete(_page([1], 2));
    await container.read(provider.future);
    final target = notifier.loadUntilEpisodeId(2);
    final error = StateError('network failed');
    final failed = expectLater(target, throwsA(same(error)));
    await _flush();
    notifier.requests[1].result.completeError(error);
    await failed;
    final state = container.read(provider).requireValue;
    expect(state.episodes.data, hasLength(1));
    expect(state.isLoadingMore, isFalse);
    expect(state.loadMoreError, same(error));
    expect(notifier.requests, hasLength(2));
    final retry = notifier.loadMore();
    await _flush();
    expect(notifier.requests.last.offset, 1);
    notifier.requests.last.result.complete(_page([2], 2));
    expect(await retry, isTrue);
    expect(container.read(provider).requireValue.loadMoreError, isNull);
  });

  for (final ids in [
    <int>[],
    [1]
  ]) {
    test('non-progress page $ids terminates even with an incorrect total',
        () async {
      notifier.requests[0].result.complete(_page([1], 20));
      await container.read(provider.future);
      final target = notifier.loadUntilEpisodeId(20);
      final failed = expectLater(target, throwsStateError);
      await _flush();
      notifier.requests[1].result.complete(_page(ids, 20));
      await failed;
      expect(container.read(provider).requireValue.hasMore, isFalse);
      expect(await notifier.loadMore(), isFalse);
      expect(notifier.requests, hasLength(2));
    });
  }

  test(
      'merge preserves watched edits and uses raw page offset after deduplication',
      () async {
    notifier.requests[0].result.complete(_page([1], 4));
    await container.read(provider.future);
    final more = notifier.loadMore();
    await _flush();
    notifier.setEpisodeWatched(episodeId: 1, watched: true);
    notifier.requests[1].result.complete(_page([1, 2], 4));
    await more;
    expect(container.read(provider).requireValue.episodes.data.first.watched,
        isTrue);
    final next = notifier.loadMore();
    await _flush();
    expect(notifier.requests.last.offset, 3);
    notifier.requests.last.result.complete(_page([3], 4));
    await next;
    expect(container.read(provider).requireValue.hasMore, isFalse);
  });

  test('initial errors reach target caller without requesting more pages',
      () async {
    final target = notifier.loadUntilEpisodeId(2);
    final failed = expectLater(target, throwsA(isA<Exception>()));
    notifier.requests[0].result.completeError(Exception('initial failure'));
    await failed;
    expect(notifier.requests, hasLength(1));
  });

  test('refresh prevents stale page responses from overwriting fresh data',
      () async {
    notifier.requests[0].result.complete(_page([1], 3));
    await container.read(provider.future);
    final old = notifier.loadMore();
    await _flush();
    final oldRequest = notifier.requests[1];
    final retry = notifier.retry();
    await _flush();
    expect(notifier.requests.last.offset, 0);
    notifier.requests.last.result.complete(_page([9], 1));
    await retry;
    oldRequest.result.complete(_page([2, 3], 3));
    expect(await old, isFalse);
    expect(container.read(provider).requireValue.episodes.data.single.id, 9);
  });

  test('completion after disposal does not publish page state', () async {
    notifier.requests[0].result.complete(_page([1], 2));
    await container.read(provider.future);
    final more = notifier.loadMore();
    await _flush();
    container.dispose();
    notifier.requests[1].result.complete(_page([2], 2));
    expect(await more, isFalse);
  });

  test('player initialization can select an episode beyond the first page',
      () async {
    final source = _Episodes();
    final player = ProviderContainer(overrides: [
      currentFlowTokenProvider.overrideWith(_GuestToken.new),
      provider.overrideWith(() => source),
      playExtraProvider.overrideWithValue(const PlayRouteExtra(
        playExtra: PlayExtra(
          subjectId: 1,
          subjectName: 'Subject',
          subjectCover: '',
          subjectAliases: [],
        ),
        continueEpisodeId: 2,
      )),
    ]);
    addTearDown(player.dispose);
    player.listen(episodesProvider, (_, next) {});
    final selected = player.read(episodesProvider.future);
    await source.firstRequest.future;
    source.requests[0].result.complete(_page([1], 2));
    await _flush();
    source.requests[1].result.complete(_page([2], 2));
    expect((await selected).episodeId, 2);
  });
}

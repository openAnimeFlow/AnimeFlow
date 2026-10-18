import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/home/data/repositories/popular_anime_repository.dart';
import 'package:anime_flow/features/home/presentation/providers/anime_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  late FutureOr<ResponseBody> Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> page(List<int> ids, {int total = 1000}) => {
      'total': total,
      'data': ids
          .map((id) => {
                'count': id + 100,
                'subject': {
                  'id': id,
                  'name': 'Anime $id',
                  'nameCN': '动画$id',
                  'type': 2,
                  'info': 'TV',
                  'metaTags': ['TV'],
                  'locked': false,
                  'nsfw': false,
                  'rating': {
                    'rank': id,
                    'count': List.filled(10, 0),
                    'score': 8.5,
                    'total': 1
                  },
                  'images': {
                    'large': 'large',
                    'common': 'common',
                    'medium': 'medium',
                    'small': 'small',
                    'grid': 'grid'
                  },
                },
              })
          .toList(),
    };

ResponseBody reply(Object? data, {int code = 200}) => ResponseBody.fromString(
      jsonEncode({'code': code, 'message': 'offline', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Adapter adapter;
  late PopularAnimeRepository repository;
  late ProviderContainer repositoryContainer;

  PopularAnimeRepository createRepository() {
    repositoryContainer = ProviderContainer(retry: (_, __) => null);
    addTearDown(repositoryContainer.dispose);
    return repositoryContainer.read(popularAnimeRepositoryProvider.notifier);
  }

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('popular_cache_test_');
    Hive.init(directory.path);
    Storage.popularAnimeCache = await Hive.openBox<String>('popular');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    await Storage.popularAnimeCache.clear();
    repository = createRepository();
    adapter = Adapter()
      ..respond = (options) {
        final offset = options.queryParameters['offset'] as int;
        final limit = options.queryParameters['limit'] as int;
        return reply(page(List.generate(limit, (index) => offset + index)));
      };
    DioFactory.animeFlowDio.interceptors.clear();
    DioFactory.animeFlowDio.httpClientAdapter = adapter;
  });
  tearDown(() {
    DioFactory.animeFlowDio.close(force: true);
    DioFactory.reset();
  });

  ProviderContainer container() {
    final c = ProviderContainer(retry: (_, __) => null);
    addTearDown(c.dispose);
    c.listen(animeHotProvider, (_, __) {});
    return c;
  }

  Future<void> agePage(String key, Duration age) async {
    final json =
        jsonDecode(Storage.popularAnimeCache.get(key)!) as Map<String, dynamic>;
    json['cachedAt'] = DateTime.now().subtract(age).millisecondsSinceEpoch;
    await Storage.popularAnimeCache.put(key, jsonEncode(json));
  }

  Future<AnimeHotState> refreshed(ProviderContainer c) {
    final done = Completer<AnimeHotState>();
    final subscription = c.listen(animeHotProvider, (_, next) {
      final value = next.asData?.value;
      if (value != null && !value.isRefreshing && !done.isCompleted) {
        done.complete(value);
      }
    }, fireImmediately: true);
    return done.future.whenComplete(subscription.close);
  }

  test('expired first page is shown before the network finishes, then replaced',
      () async {
    await repository.getPage(limit: 20, offset: 0);
    await repository.getPage(limit: 20, offset: 20);
    await agePage('20:0', const Duration(hours: 13));
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    adapter.respond = (_) {
      started.complete();
      return pending.future;
    };
    final c = container();
    final initial = await c.read(animeHotProvider.future);
    expect(initial.items.first.subject.id, 0);
    expect(initial.isRefreshing, isTrue);
    await started.future;
    await c.read(animeHotProvider.notifier).loadMore();
    expect(adapter.requests, hasLength(3));
    final update = refreshed(c);
    pending.complete(reply(page([900], total: 1)));
    final result = await update;
    expect(result.items.single.subject.id, 900);
    expect(result.hasMore, isFalse);
    expect(result.hasUpdate, isFalse);
    expect(Storage.popularAnimeCache.keys.toList(), ['20:0']);
  });

  test(
      'failed background refresh preserves displayed data and cache timestamps',
      () async {
    await repository.getPage(limit: 20, offset: 0);
    await repository.getPage(limit: 20, offset: 20);
    await agePage('20:0', const Duration(hours: 13));
    final before = Storage.popularAnimeCache.toMap();
    adapter.respond = (_) => reply(null, code: 500);
    final c = container();
    await c.read(animeHotProvider.future);
    final result = await refreshed(c);
    expect(result.items, hasLength(20));
    expect(result.hasUpdate, isFalse);
    expect(Storage.popularAnimeCache.toMap(), before);
    await c.read(animeHotProvider.notifier).loadMore();
    expect(c.read(animeHotProvider).requireValue.items, hasLength(40));
  });

  test(
      'scrolling defers replacement and blocks mixing pages until update is applied',
      () async {
    await repository.getPage(limit: 20, offset: 0);
    await agePage('20:0', const Duration(hours: 13));
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    adapter.respond = (_) {
      started.complete();
      return pending.future;
    };
    final c = container();
    await c.read(animeHotProvider.future);
    await started.future;
    c.read(animeHotProvider.notifier).markScrolled();
    final update = refreshed(c);
    pending.complete(reply(page([900, 901], total: 3)));
    final result = await update;
    expect(result.items.first.subject.id, 0);
    expect(result.hasUpdate, isTrue);
    await c.read(animeHotProvider.notifier).loadMore();
    expect(adapter.requests, hasLength(2));
    c.read(animeHotProvider.notifier).applyUpdate();
    expect(c.read(animeHotProvider).requireValue.nextOffset, 2);
    expect(c.read(animeHotProvider).requireValue.hasUpdate, isFalse);
    adapter.respond = (_) => reply(page([902], total: 3));
    await c.read(animeHotProvider.notifier).loadMore();
    expect(adapter.requests.last.queryParameters['offset'], 2);
    expect(c.read(animeHotProvider).requireValue.items.map((e) => e.subject.id),
        [900, 901, 902]);
  });

  test(
      'manual refresh cancels background refresh and keeps visible data while waiting',
      () async {
    await repository.getPage(limit: 20, offset: 0);
    await agePage('20:0', const Duration(hours: 13));
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    adapter.respond = (_) {
      started.complete();
      return pending.future;
    };
    final c = container();
    await c.read(animeHotProvider.future);
    await started.future;
    final manual = Completer<ResponseBody>();
    adapter.respond = (_) => manual.future;
    final refresh = c.read(animeHotProvider.notifier).refresh();
    expect(c.read(animeHotProvider).requireValue.items.first.subject.id, 0);
    manual.complete(reply(page([999], total: 1)));
    await refresh;
    pending.complete(reply(page([888], total: 1)));
    // Allow the cancelled adapter response to settle before inspecting disk.
    await Future<void>.delayed(Duration.zero);
    expect(c.read(animeHotProvider).requireValue.items.single.subject.id, 999);
    expect(
        repository.readPage(limit: 20, offset: 0)!.data.data.single.subject.id,
        999);
  });

  test('leaving the page cancels background refresh without writing late data',
      () async {
    await repository.getPage(limit: 20, offset: 0);
    await agePage('20:0', const Duration(hours: 13));
    final before = Storage.popularAnimeCache.toMap();
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    adapter.respond = (_) {
      started.complete();
      return pending.future;
    };
    final c = ProviderContainer(retry: (_, __) => null);
    addTearDown(c.dispose);
    final subscription = c.listen(animeHotProvider, (_, __) {});
    await c.read(animeHotProvider.future);
    await started.future;
    subscription.close();
    await c.pump();
    expect(adapter.requests.last.cancelToken!.isCancelled, isTrue);
    pending.complete(reply(page([999], total: 1)));
    await Future<void>.delayed(Duration.zero);
    expect(Storage.popularAnimeCache.toMap(), before);
  });

  test('reopened provider reuses cached pages and retains all model fields',
      () async {
    final first = container();
    await first.read(animeHotProvider.future);
    await first.read(animeHotProvider.notifier).loadMore();
    expect(adapter.requests, hasLength(2));
    repository = createRepository();
    final reopened = container();
    await reopened.read(animeHotProvider.future);
    await reopened.read(animeHotProvider.notifier).loadMore();
    expect(adapter.requests, hasLength(2));
    expect(
        reopened
            .read(animeHotProvider)
            .requireValue
            .items
            .map((item) => item.toJson()),
        page(List.generate(40, (index) => index))['data']);
    expect(reopened.read(animeHotProvider).requireValue.nextOffset, 40);
    expect(
        adapter.requests
            .every((request) => request.queryParameters['type'] == 2),
        isTrue);
  });

  test('evicting page one at 20 pages does not remove visible items', () async {
    final c = container();
    await c.read(animeHotProvider.future);
    await agePage('20:0', const Duration(hours: 1));
    for (var i = 0; i < 20; i++) {
      await c.read(animeHotProvider.notifier).loadMore();
    }
    expect(Storage.popularAnimeCache.length, 20);
    expect(Storage.popularAnimeCache.containsKey('20:0'), isFalse);
    expect(c.read(animeHotProvider).requireValue.items, hasLength(420));
    expect(c.read(animeHotProvider).requireValue.items.first.subject.id, 0);
    adapter.respond = (_) => reply(page([999]));
    final reopened = container();
    expect(
        (await reopened.read(animeHotProvider.future)).items.single.subject.id,
        999);
    expect(Storage.popularAnimeCache.keys.toList(), ['20:0']);
    expect(c.read(animeHotProvider).requireValue.items, hasLength(420));
  });

  test('cache uses the default 12 hour expiry and separates page sizes',
      () async {
    await repository.getPage(limit: 20, offset: 0);
    await agePage('20:0', const Duration(hours: 11));
    await repository.getPage(limit: 20, offset: 0);
    expect(adapter.requests, hasLength(1));
    await agePage('20:0', const Duration(hours: 13));
    await repository.getPage(limit: 20, offset: 0);
    expect(adapter.requests, hasLength(2));
    await repository.getPage(limit: 10, offset: 20);
    await repository.getPage(limit: 20, offset: 20);
    await repository.getPage(limit: 10, offset: 20);
    await repository.getPage(limit: 20, offset: 20);
    expect(adapter.requests, hasLength(4));
  });

  test(
      'failed refresh falls back without erasing old pages or extending expiry',
      () async {
    final c = container();
    await c.read(animeHotProvider.future);
    await c.read(animeHotProvider.notifier).loadMore();
    final before = Storage.popularAnimeCache.toMap();
    adapter.respond = (_) => reply(null, code: 500);
    await c.read(animeHotProvider.notifier).refresh();
    expect(c.read(animeHotProvider).requireValue.items, hasLength(40));
    expect(Storage.popularAnimeCache.toMap(), before);
    adapter.respond = (_) => reply(page([40], total: 41));
    await c.read(animeHotProvider.notifier).loadMore();
    expect(c.read(animeHotProvider).requireValue.items, hasLength(41));
    expect(adapter.requests, hasLength(4));
  });

  test(
      'refresh cancels an old loadMore and prevents late state or cache writes',
      () async {
    final c = container();
    await c.read(animeHotProvider.future);
    final started = Completer<void>();
    final pending = Completer<ResponseBody>();
    adapter.respond = (options) {
      if (options.queryParameters['offset'] == 20) {
        started.complete();
        return pending.future;
      }
      return reply(page([900], total: 1));
    };
    final load = c.read(animeHotProvider.notifier).loadMore();
    await started.future;
    await c.read(animeHotProvider.notifier).refresh();
    pending.complete(reply(page([20, 21])));
    await load;
    expect(c.read(animeHotProvider).requireValue.items.single.subject.id, 900);
    expect(c.read(animeHotProvider).requireValue.hasMore, isFalse);
    expect(Storage.popularAnimeCache.keys.toList(), ['20:0']);
  });

  test('duplicates do not change the next offset and empty pages stop loading',
      () async {
    adapter.respond = (options) => switch (options.queryParameters['offset']) {
          0 => reply(page([1, 2], total: 10)),
          2 => reply(page([2, 3], total: 10)),
          _ => reply(page([], total: 10)),
        };
    final c = container();
    await c.read(animeHotProvider.future);
    await c.read(animeHotProvider.notifier).loadMore();
    expect(
        c
            .read(animeHotProvider)
            .requireValue
            .items
            .map((item) => item.subject.id),
        [1, 2, 3]);
    expect(c.read(animeHotProvider).requireValue.nextOffset, 4);
    await c.read(animeHotProvider.notifier).loadMore();
    expect(adapter.requests.last.queryParameters['offset'], 4);
    expect(c.read(animeHotProvider).requireValue.hasMore, isFalse);
    await c.read(animeHotProvider.notifier).loadMore();
    expect(adapter.requests, hasLength(3));
  });

  test('failed loadMore keeps items and retries the same offset', () async {
    final c = container();
    await c.read(animeHotProvider.future);
    adapter.respond = (_) => reply(null, code: 500);
    await c.read(animeHotProvider.notifier).loadMore();
    expect(c.read(animeHotProvider).requireValue.items, hasLength(20));
    expect(c.read(animeHotProvider).requireValue.nextOffset, 20);
    expect(c.read(animeHotProvider).requireValue.errorMessage, isNotNull);
    adapter.respond = (_) => reply(page([20], total: 21));
    await c.read(animeHotProvider.notifier).loadMore();
    expect(adapter.requests.last.queryParameters['offset'], 20);
    expect(c.read(animeHotProvider).requireValue.errorMessage, isNull);
    expect(c.read(animeHotProvider).requireValue.items, hasLength(21));
  });
}

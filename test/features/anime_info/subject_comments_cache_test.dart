import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/shared/navigation/args/info_route_extra.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/anime_info/data/repositories/anime_info_repository.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

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
                'id': id,
                'type': 3,
                'rate': 8,
                'comment': '吐槽$id',
                'updatedAt': 123,
                'user': {
                  'id': id,
                  'username': 'user$id',
                  'nickname': '用户$id',
                  'avatar': {
                    'small': 'small',
                    'medium': 'medium',
                    'large': 'large'
                  },
                  'group': 10,
                  'sign': '',
                  'joinedAt': 0
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

@Dependencies([SubjectComments])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Adapter adapter;
  late AnimeInfoRepository repository;
  late ProviderContainer repositoryContainer;

  AnimeInfoRepository createRepository() {
    repositoryContainer = ProviderContainer(retry: (_, __) => null);
    addTearDown(repositoryContainer.dispose);
    return repositoryContainer.read(animeInfoRepositoryProvider.notifier);
  }

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('comments_cache_test_');
    Hive.init(directory.path);
    Storage.subjectCommentsCache = await Hive.openBox<String>('comments');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    await Storage.subjectCommentsCache.clear();
    repository = createRepository();
    adapter = Adapter()
      ..respond =
          (options) => reply(page([options.queryParameters['offset'] as int]));
    DioFactory.animeFlowDio.interceptors.clear();
    DioFactory.animeFlowDio.httpClientAdapter = adapter;
  });
  tearDown(() {
    DioFactory.animeFlowDio.close(force: true);
    DioFactory.reset();
  });

  @Dependencies([SubjectComments])
  ProviderContainer container() {
    final c = ProviderContainer(
        parent: repositoryContainer,
        retry: (_, __) => null,
        overrides: [
          animeInfoArgsProvider
              .overrideWithValue(InfoRouteExtra(id: 42, name: '', image: '')),
        ]);
    addTearDown(c.dispose);
    c.listen(subjectCommentsProvider, (_, __) {});
    return c;
  }

  Future<void> agePage(String key, Duration age) async {
    final json = jsonDecode(Storage.subjectCommentsCache.get(key)!)
        as Map<String, dynamic>;
    json['cachedAt'] = DateTime.now().subtract(age).millisecondsSinceEpoch;
    await Storage.subjectCommentsCache.put(key, jsonEncode(json));
  }

  test('comments are reusable for one hour and refresh after expiry', () async {
    expect((await repository.getComments(42, limit: 20, offset: 0)).toJson(),
        page([0]));
    await agePage('42:20:0', const Duration(minutes: 59));
    await createRepository().getComments(42, limit: 20, offset: 0);
    expect(adapter.requests, hasLength(1));
    await agePage('42:20:0', const Duration(minutes: 61));
    adapter.respond = (_) => reply(page([100]));
    expect(
        (await repository.getComments(42, limit: 20, offset: 0)).data.single.id,
        100);
    expect(adapter.requests, hasLength(2));
  });

  test(
      'evicting page one leaves visible comments intact and reopening replaces old pages',
      () async {
    final c = container();
    final initial = await c.read(subjectCommentsProvider.future);
    // Make the eviction order deterministic without waiting for the clock.
    await agePage('42:20:0', const Duration(minutes: 30));
    for (var index = 1; index <= 20; index++) {
      await repository.getComments(42, limit: 20, offset: index * 20);
    }
    expect(Storage.subjectCommentsCache.length, 20);
    expect(Storage.subjectCommentsCache.containsKey('42:20:0'), isFalse);
    expect(c.read(subjectCommentsProvider).requireValue.comments.toJson(),
        initial.comments.toJson());

    adapter.respond = (_) => reply(page([999]));
    final reopened = container();
    expect(
        (await reopened.read(subjectCommentsProvider.future))
            .comments
            .data
            .single
            .id,
        999);
    expect(Storage.subjectCommentsCache.keys.toList(), ['42:20:0']);
    expect(c.read(subjectCommentsProvider).requireValue.comments.data.single.id,
        0);
  });

  test(
      'capacity is 20 pages across subjects and page keys include limit and offset',
      () async {
    for (var id = 1; id <= 21; id++) {
      await repository.getComments(id, limit: 20, offset: 0);
      if (id == 1) await agePage('1:20:0', const Duration(minutes: 30));
    }
    expect(Storage.subjectCommentsCache.length, 20);
    expect(Storage.subjectCommentsCache.containsKey('1:20:0'), isFalse);
    await repository.getComments(21, limit: 10, offset: 20);
    await repository.getComments(21, limit: 20, offset: 20);
    final count = adapter.requests.length;
    await repository.getComments(21, limit: 10, offset: 20);
    await repository.getComments(21, limit: 20, offset: 20);
    expect(adapter.requests, hasLength(count));
    expect(Storage.subjectCommentsCache.length, 20);
  });

  test('failed refresh preserves cached pages and timestamps', () async {
    await repository.getComments(42, limit: 20, offset: 0);
    await repository.getComments(42, limit: 20, offset: 20);
    await agePage('42:20:0', const Duration(hours: 2));
    final before = Storage.subjectCommentsCache.toMap();
    adapter.respond = (_) => reply(null, code: 500);
    expect(
        (await repository.getComments(42, limit: 20, offset: 0)).data.single.id,
        0);
    expect(Storage.subjectCommentsCache.toMap(), before);
    await expectLater(repository.getComments(99, limit: 20, offset: 0),
        throwsA(isA<AnimeFlowApiException>()));
  });

  test('successful homepage refresh removes only that subject cache', () async {
    await repository.getComments(42, limit: 20, offset: 0);
    await repository.getComments(42, limit: 20, offset: 20);
    await repository.getComments(43, limit: 20, offset: 20);
    final c = container();
    await c.read(subjectCommentsProvider.future);
    expect(adapter.requests, hasLength(3));
    adapter.respond = (_) => reply(page([200]));
    c.invalidate(subjectCommentsProvider);
    expect(
        (await c.read(subjectCommentsProvider.future)).comments.data.single.id,
        200);
    expect(Storage.subjectCommentsCache.containsKey('42:20:20'), isFalse);
    expect(Storage.subjectCommentsCache.containsKey('43:20:20'), isTrue);
    await repository.getComments(42, limit: 20, offset: 20);
    expect(adapter.requests, hasLength(5));
  });

  test('explicit refresh resets pagination and clears only its subject cache',
      () async {
    adapter.respond = (options) => reply(page(
        options.queryParameters['offset'] == 0
            ? List.generate(20, (index) => index + 1)
            : [21]));
    final c = container();
    await c.read(subjectCommentsProvider.future);
    final notifier = c.read(subjectCommentsProvider.notifier);
    await notifier.loadMore();
    await repository.getComments(43, limit: 20, offset: 20);
    expect(c.read(subjectCommentsProvider).requireValue.nextOffset, 21);

    adapter.respond = (_) => reply(page([100]));
    notifier.refresh();
    final refreshed = await c.read(subjectCommentsProvider.future);

    expect(refreshed.comments.data.single.id, 100);
    expect(refreshed.nextOffset, 1);
    expect(adapter.requests, hasLength(4));
    expect(adapter.requests.last.queryParameters['offset'], 0);
    expect(Storage.subjectCommentsCache.containsKey('42:20:20'), isFalse);
    expect(Storage.subjectCommentsCache.containsKey('43:20:20'), isTrue);
  });

  test('refresh discards a late pagination response', () async {
    final c = container();
    await c.read(subjectCommentsProvider.future);
    final started = Completer<void>();
    final pending = Completer<ResponseBody>();
    adapter.respond = (options) {
      if (options.queryParameters['offset'] != 0) {
        started.complete();
        return pending.future;
      }
      return reply(page([100]));
    };
    final notifier = c.read(subjectCommentsProvider.notifier);
    final loading = notifier.loadMore();
    await started.future;

    notifier.refresh();
    await c.read(subjectCommentsProvider.future);
    pending.complete(reply(page([2])));
    await loading;

    final current = c.read(subjectCommentsProvider).requireValue;
    expect(current.comments.data.map((comment) => comment.id), [100]);
    expect(current.nextOffset, 1);
    expect(Storage.subjectCommentsCache.containsKey('42:20:1'), isFalse);
  });

  test('invalidated in-flight page retries without restoring old data',
      () async {
    final started = Completer<void>();
    final pending = Completer<ResponseBody>();
    adapter.respond = (_) {
      if (!started.isCompleted) {
        started.complete();
        return pending.future;
      }
      return reply(page([500]));
    };
    final result = repository.getComments(42, limit: 20, offset: 20);
    await started.future;
    await repository.invalidateCommentsCache(42);
    pending.complete(reply(page([1])));
    expect((await result).data.single.id, 500);
    expect(adapter.requests, hasLength(2));
    final json = jsonDecode(Storage.subjectCommentsCache.get('42:20:20')!);
    expect(json['data']['data'].single['id'], 500);
  });

  test(
      'pagination deduplicates IDs but advances by server rows and stops on empty page',
      () async {
    adapter.respond = (options) => switch (options.queryParameters['offset']) {
          0 => reply(page([1, 2], total: 6)),
          2 => reply(page([2, 3], total: 6)),
          _ => reply(page([], total: 6)),
        };
    final c = container();
    await c.read(subjectCommentsProvider.future);
    final notifier = c.read(subjectCommentsProvider.notifier);
    await notifier.loadMore();
    final state = c.read(subjectCommentsProvider).requireValue;
    expect(state.comments.data.map((item) => item.id), [1, 2, 3]);
    expect(state.nextOffset, 4);
    await notifier.loadMore();
    expect(adapter.requests.last.queryParameters['offset'], 4);
    expect(c.read(subjectCommentsProvider).requireValue.hasMore, isFalse);
    await notifier.loadMore();
    expect(adapter.requests, hasLength(3));
  });

  test('cancelled requests neither retry nor cache a late response', () async {
    final started = Completer<void>();
    final pending = Completer<ResponseBody>();
    adapter.respond = (_) {
      started.complete();
      return pending.future;
    };
    final token = CancelToken();
    final result =
        repository.getComments(42, limit: 20, offset: 20, cancelToken: token);
    final assertion = expectLater(
        result,
        throwsA(isA<DioException>()
            .having((error) => error.type, 'type', DioExceptionType.cancel)));
    await started.future;
    await repository.invalidateCommentsCache(42);
    token.cancel();
    pending.complete(reply(page([1])));
    await assertion;
    expect(adapter.requests, hasLength(1));
    expect(Storage.subjectCommentsCache.isEmpty, isTrue);
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/app/router/model/character_info_extra.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/character_info/presentation/providers/character_info_provider.dart';
import 'package:anime_flow/features/characters/data/repositories/character_repository.dart';
import 'package:anime_flow/features/characters/presentation/providers/characters_provider.dart';
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

ResponseBody reply(Object? data, {int code = 200}) => ResponseBody.fromString(
      jsonEncode({'code': code, 'message': 'unavailable', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );

Map<String, dynamic> detail(int id, {String name = '角色'}) => {
      'id': id,
      'name': name,
      'nameCN': '角色中文名',
      'role': 1,
      'info': '人物信息',
      'summary': '人物简介',
      'comment': 12,
      'collects': 7,
      'infobox': [
        {
          'key': '别名',
          'values': [
            {'k': '昵称', 'v': '测试'}
          ]
        }
      ],
      'lock': false,
      'redirect': 0,
      'nsfw': false,
      'images': {
        'large': 'large',
        'medium': 'medium',
        'small': 'small',
        'grid': 'grid'
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Adapter adapter;
  late CharacterRepository repository;
  late ProviderContainer repositoryContainer;

  CharacterRepository createRepository() {
    repositoryContainer = ProviderContainer(retry: (_, __) => null);
    addTearDown(repositoryContainer.dispose);
    return repositoryContainer.read(characterRepositoryProvider.notifier);
  }

  final charactersJson = jsonDecode(
      File('test/shared/models/fixtures/subject_characters.json')
          .readAsStringSync()) as Map<String, dynamic>;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('character_cache_test_');
    Hive.init(directory.path);
    Storage.characterDataCache = await Hive.openBox<String>('character_cache');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    await Storage.characterDataCache.clear();
    repository = createRepository();
    adapter = Adapter()..respond = (_) => reply(charactersJson);
    DioFactory.animeFlowDio.interceptors.clear();
    DioFactory.animeFlowDio.httpClientAdapter = adapter;
  });
  tearDown(() {
    DioFactory.animeFlowDio.close(force: true);
    DioFactory.reset();
  });

  Future<void> expireCache() async {
    for (final entry in Storage.characterDataCache.toMap().entries) {
      final json = jsonDecode(entry.value) as Map<String, dynamic>;
      json['cachedAt'] = DateTime.now()
          .subtract(const Duration(hours: 13))
          .millisecondsSinceEpoch;
      await Storage.characterDataCache.put(entry.key, jsonEncode(json));
    }
  }

  test('role preview and full list share cached pages and preserve casts',
      () async {
    final c = ProviderContainer(overrides: [
      animeInfoArgsProvider
          .overrideWithValue(InfoRouteExtra(id: 42, name: '', image: '')),
      charactersArgsProvider.overrideWithValue(42),
    ]);
    addTearDown(c.dispose);
    c.listen(subjectCharactersProvider, (_, __) {});
    final preview = await c.read(subjectCharactersProvider.future);
    c.listen(charactersListProvider, (_, __) {});
    final list = await c.read(charactersListProvider.future);
    expect(preview.toJson(), charactersJson);
    expect(list.characters.toJson(), charactersJson);
    expect(adapter.requests, hasLength(1));
    final cached =
        await createRepository().getCharacters(42, limit: 10, offset: 0);
    expect(cached.toJson(), charactersJson);
    expect(adapter.requests, hasLength(1));
    await c.read(charactersListProvider.notifier).loadMore();
    expect(adapter.requests.last.queryParameters['offset'], 10);
    expect(c.read(charactersListProvider).requireValue.characters.data,
        hasLength(20));
  });

  test('list cache separates subjects, limits, offsets and role filters',
      () async {
    for (final args in [
      (id: 42, limit: 10, offset: 0, type: null),
      (id: 43, limit: 10, offset: 0, type: null),
      (id: 42, limit: 20, offset: 0, type: null),
      (id: 42, limit: 10, offset: 10, type: null),
      (id: 42, limit: 10, offset: 0, type: 1),
    ]) {
      await repository.getCharacters(args.id,
          limit: args.limit, offset: args.offset, type: args.type);
      await repository.getCharacters(args.id,
          limit: args.limit, offset: args.offset, type: args.type);
    }
    expect(adapter.requests, hasLength(5));
    expect(Storage.characterDataCache.length, 5);
  });

  test('detail survives reopening and explicit provider refresh bypasses cache',
      () async {
    adapter.respond = (_) => reply(detail(42));
    final first = await repository.getDetail(42);
    expect(first.toJson(), detail(42));
    final c = ProviderContainer(overrides: [
      characterInfoArgsProvider.overrideWithValue(const CharacterInfoExtra(
          characterId: 42, characterName: '', characterImage: '')),
    ]);
    addTearDown(c.dispose);
    c.listen(characterInfoDetailProvider, (_, __) {});
    expect((await c.read(characterInfoDetailProvider.future)).toJson(),
        first.toJson());
    expect(adapter.requests, hasLength(1));
    adapter.respond = (_) => reply(detail(42, name: '最新角色'));
    c.invalidate(characterInfoDetailProvider);
    expect((await c.read(characterInfoDetailProvider.future)).name, '最新角色');
    expect(adapter.requests, hasLength(2));
  });

  test('works cache separates character, pagination and subject type',
      () async {
    final works = {
      'total': 1,
      'data': [
        {
          'type': 1,
          'actors': (charactersJson['data'] as List)
              .first['casts']
              .map((cast) => cast['person'])
              .toList(),
          'subject': {
            'id': 7,
            'name': '作品',
            'nameCN': '',
            'type': 2,
            'info': '',
            'metaTags': ['TV'],
            'locked': false,
            'nsfw': false,
            'rating': {
              'rank': 1,
              'count': List.filled(10, 0),
              'score': 8.5,
              'total': 1
            },
            'images': {
              'large': '',
              'common': '',
              'medium': '',
              'small': '',
              'grid': ''
            }
          },
        }
      ],
    };
    adapter.respond = (_) => reply(works);
    for (final args in [
      (id: 42, limit: 20, offset: 0, type: 2),
      (id: 43, limit: 20, offset: 0, type: 2),
      (id: 42, limit: 10, offset: 0, type: 2),
      (id: 42, limit: 20, offset: 20, type: 2),
      (id: 42, limit: 20, offset: 0, type: 1),
    ]) {
      await repository.getWorks(args.id,
          limit: args.limit, offset: args.offset, subjectType: args.type);
      final cached = await createRepository().getWorks(args.id,
          limit: args.limit, offset: args.offset, subjectType: args.type);
      expect(cached.toJson(), works);
    }
    expect(adapter.requests, hasLength(5));
  });

  test('expired detail is refreshed and offline fallback keeps its timestamp',
      () async {
    adapter.respond = (_) => reply(detail(42));
    await repository.getDetail(42);
    await expireCache();
    adapter.respond = (_) => reply(detail(42, name: 'updated'));
    expect((await repository.getDetail(42)).name, 'updated');
    await expireCache();
    final before = Storage.characterDataCache.toMap();
    adapter.respond = (_) => reply(null, code: 500);
    expect((await repository.getDetail(42)).name, 'updated');
    expect(Storage.characterDataCache.toMap(), before);
    expect(adapter.requests, hasLength(3));
    await expectLater(
        repository.getDetail(43), throwsA(isA<AnimeFlowApiException>()));
  });

  test('corrupt cache is replaced by a successful response', () async {
    adapter.respond = (_) => reply(detail(42));
    await repository.getDetail(42);
    await Storage.characterDataCache
        .put(Storage.characterDataCache.keys.single, 'broken');
    expect((await repository.getDetail(42)).id, 42);
    expect(adapter.requests, hasLength(2));
    expect(jsonDecode(Storage.characterDataCache.values.single)['data'],
        detail(42));
  });

  test('cancellation never falls back to stale cache or writes late data',
      () async {
    adapter.respond = (_) => reply(detail(42));
    await repository.getDetail(42);
    await expireCache();
    final before = Storage.characterDataCache.toMap();
    final started = Completer<void>();
    final pending = Completer<ResponseBody>();
    adapter.respond = (_) {
      started.complete();
      return pending.future;
    };
    final token = CancelToken();
    final result = repository.getDetail(42, cancelToken: token);
    final assertion = expectLater(
        result,
        throwsA(isA<DioException>()
            .having((error) => error.type, 'type', DioExceptionType.cancel)));
    await started.future;
    token.cancel();
    pending.complete(reply(detail(42, name: 'late')));
    await assertion;
    expect(Storage.characterDataCache.toMap(), before);
  });

  test('cache evicts oldest records above 100 entries', () async {
    for (var id = 0; id < 100; id++) {
      await Storage.characterDataCache.put(
          'old-$id',
          jsonEncode({
            'cachedAt': id,
            'data': detail(id),
          }));
    }
    adapter.respond = (_) => reply(detail(101));
    await repository.getDetail(101);
    expect(Storage.characterDataCache.length, 100);
    expect(Storage.characterDataCache.containsKey('old-0'), isFalse);
    expect(Storage.characterDataCache.containsKey('old-1'), isTrue);
    expect((await repository.getDetail(101)).id, 101);
    expect(adapter.requests, hasLength(1));
  });
}

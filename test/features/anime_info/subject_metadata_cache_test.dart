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

ResponseBody reply(Object? data, {int code = 200}) => ResponseBody.fromString(
      jsonEncode({'code': code, 'message': 'unavailable', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );

final producers = <String, dynamic>{
  'total': 1,
  'data': [
    {
      'staff': {
        'id': 1,
        'name': '制作人',
        'nameCN': '制作人中文名',
        'type': 1,
        'info': '简介',
        'career': ['director', 'writer'],
        'comment': 5,
        'lock': false,
        'nsfw': false,
        'images': {
          'large': 'large',
          'medium': 'medium',
          'small': 'small',
          'grid': 'grid'
        },
      },
      'positions': [
        {
          'type': {'id': 1, 'en': 'Director', 'cn': '导演', 'jp': '監督'},
          'summary': '制作说明',
          'appearEps': '1-12',
        }
      ],
    }
  ],
};

final related = <String, dynamic>{
  'total': 1,
  'data': [
    {
      'subject': {
        'id': 7,
        'name': '关联作品',
        'nameCN': '作品中文名',
        'type': 2,
        'info': '2026',
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
          'large': 'large',
          'common': 'common',
          'medium': 'medium',
          'small': 'small',
          'grid': 'grid'
        },
      },
      'relation': {
        'id': 1,
        'en': 'Sequel',
        'cn': '续集',
        'jp': '続編',
        'desc': '后续故事'
      },
      'order': 2,
    }
  ],
};

@Dependencies([SubjectProducers, SubjectRelated])
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
    directory = await Directory.systemTemp.createTemp('subject_metadata_test_');
    Hive.init(directory.path);
    Storage.animeInfoCache = await Hive.openBox<String>('subject_cache');
    Storage.subjectMetadataCache = await Hive.openBox<String>('metadata_cache');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    await Storage.subjectMetadataCache.clear();
    repository = createRepository();
    adapter = Adapter()
      ..respond = (options) =>
          reply(options.path.endsWith('/staffs/persons') ? producers : related);
    DioFactory.animeFlowDio.interceptors.clear();
    DioFactory.animeFlowDio.httpClientAdapter = adapter;
  });
  tearDown(() {
    DioFactory.animeFlowDio.close(force: true);
    DioFactory.reset();
  });

  Future<Map<String, dynamic>> load(
    String kind, {
    int id = 42,
    int limit = 10,
    int offset = 0,
    int? type = 2,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    if (kind == 'producers') {
      return (await repository.getProducers(id,
              limit: limit,
              offset: offset,
              forceRefresh: forceRefresh,
              cancelToken: cancelToken))
          .toJson();
    }
    return (await repository.getRelated(id,
            limit: limit,
            offset: offset,
            type: type,
            forceRefresh: forceRefresh,
            cancelToken: cancelToken))
        .toJson();
  }

  Future<void> expireCache() async {
    for (final entry in Storage.subjectMetadataCache.toMap().entries) {
      final json = jsonDecode(entry.value) as Map<String, dynamic>;
      json['cachedAt'] = 0;
      await Storage.subjectMetadataCache.put(entry.key, jsonEncode(json));
    }
  }

  for (final kind in ['producers', 'related']) {
    final fixture = kind == 'producers' ? producers : related;

    test('$kind persists all fields and survives collection invalidation',
        () async {
      expect(await load(kind), fixture);
      repository = createRepository();
      repository.invalidateCache();
      expect(await load(kind), fixture);
      expect(adapter.requests, hasLength(1));
      expect(Storage.subjectMetadataCache.length, 1);
      expect(await load(kind, forceRefresh: true), fixture);
      expect(adapter.requests, hasLength(2));
    });

    test('$kind refreshes expired data and falls back without renewing it',
        () async {
      await load(kind);
      await expireCache();
      final updated = {...fixture, 'total': 2};
      adapter.respond = (_) => reply(updated);
      expect(await load(kind), updated);
      await expireCache();
      final before = Storage.subjectMetadataCache.toMap();
      adapter.respond = (_) => reply(null, code: 500);
      expect(await load(kind), updated);
      expect(Storage.subjectMetadataCache.toMap(), before);
      expect(adapter.requests, hasLength(3));
      await expectLater(
          load(kind, id: 99), throwsA(isA<AnimeFlowApiException>()));
    });

    test('$kind cancellation does not return or overwrite old data', () async {
      await load(kind);
      await expireCache();
      final before = Storage.subjectMetadataCache.toMap();
      final started = Completer<void>();
      final pending = Completer<ResponseBody>();
      adapter.respond = (_) {
        started.complete();
        return pending.future;
      };
      final token = CancelToken();
      final result = load(kind, cancelToken: token);
      final assertion = expectLater(
          result,
          throwsA(isA<DioException>()
              .having((error) => error.type, 'type', DioExceptionType.cancel)));
      await started.future;
      token.cancel();
      pending.complete(reply({...fixture, 'total': 3}));
      await assertion;
      expect(Storage.subjectMetadataCache.toMap(), before);
    });
  }

  test('cache keys isolate resource, subject, pagination and relation type',
      () async {
    for (final kind in ['producers', 'related']) {
      for (final args in [
        (id: 42, limit: 10, offset: 0),
        (id: 43, limit: 10, offset: 0),
        (id: 42, limit: 20, offset: 0),
        (id: 42, limit: 10, offset: 10),
      ]) {
        await load(kind, id: args.id, limit: args.limit, offset: args.offset);
        await load(kind, id: args.id, limit: args.limit, offset: args.offset);
      }
    }
    for (final type in [1, null]) {
      await load('related', type: type);
      await load('related', type: type);
    }
    expect(adapter.requests, hasLength(10));
    expect(Storage.subjectMetadataCache.length, 10);
    expect(adapter.requests[8].queryParameters['type'], 1);
    expect(adapter.requests[9].queryParameters['type'], isNull);
  });

  test('both page providers use cache and bypass it when invalidated',
      () async {
    await repository.getProducers(42, limit: 10, offset: 0);
    await repository.getRelated(42, limit: 20, offset: 0);
    final c = ProviderContainer(overrides: [
      animeInfoArgsProvider
          .overrideWithValue(InfoRouteExtra(id: 42, name: '', image: '')),
    ]);
    addTearDown(c.dispose);
    c.listen(subjectProducersProvider, (_, __) {});
    c.listen(subjectRelatedProvider, (_, __) {});
    expect((await c.read(subjectProducersProvider.future)).toJson(), producers);
    expect((await c.read(subjectRelatedProvider.future)).toJson(), related);
    expect(adapter.requests, hasLength(2));
    c.invalidate(subjectProducersProvider);
    c.invalidate(subjectRelatedProvider);
    await c.read(subjectProducersProvider.future);
    await c.read(subjectRelatedProvider.future);
    expect(adapter.requests, hasLength(4));
  });
}

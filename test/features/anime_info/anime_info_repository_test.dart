import 'package:anime_flow/features/auth/auth_api.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/shared/navigation/args/info_route_extra.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/cache/json_response_cache.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/anime_info/data/datasources/anime_info_local_data_source.dart';
import 'package:anime_flow/features/anime_info/data/repositories/anime_info_repository.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/user/application/collection_revision_provider.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class GuestToken extends CurrentFlowToken {
  @override
  Future<FlowToken?> build() async => null;
}

class PendingAdapter implements HttpClientAdapter {
  final requests = <Completer<ResponseBody>>[];
  var _requestAdded = Completer<void>();

  Future<void> waitForRequests(int count) async {
    while (requests.length < count) {
      await _requestAdded.future.timeout(const Duration(seconds: 10),
          onTimeout: () => throw TestFailure(
              'Expected $count requests, but received ${requests.length}.'));
    }
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    final request = Completer<ResponseBody>();
    requests.add(request);
    final added = _requestAdded;
    _requestAdded = Completer<void>();
    added.complete();
    return request.future;
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody reply({SubjectsInfoItem? subject, String? error}) =>
    ResponseBody.fromString(
      jsonEncode({
        'code': error == null ? 200 : 500,
        'message': error ?? '',
        'data': subject?.toJson(),
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );

SubjectsInfoItem subject(String name) => SubjectsInfoItem.fromJson({
      'id': 42,
      'name': name,
      'collection': <String, dynamic>{},
      'eps': 0,
      'volumes': 0,
      'infobox': <dynamic>[],
      'info': '',
      'metaTags': <String>[],
      'locked': false,
      'nsfw': false,
      'series': false,
      'redirect': 0,
      'seriesEntry': 0,
      'summary': '',
      'type': 2,
      'platform': {
        'id': 1,
        'type': 'TV',
        'typeCN': 'TV',
        'alias': 'tv',
        'order': 0,
        'enableHeader': true,
        'wikiTpl': 'TVAnime',
      },
      'rating': <String, dynamic>{},
      'tags': <dynamic>[],
      'images': <String, String>{},
    });

@Dependencies([AnimeInfo, SubjectComments])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory cacheDirectory;
  final local = AnimeInfoLocalDataSource();
  late PendingAdapter remote;
  late AnimeInfoRepository repository;
  late ProviderContainer repositoryContainer;

  AnimeInfoRepository createRepository() {
    repositoryContainer = ProviderContainer(
      retry: (_, __) => null,
      overrides: [currentFlowTokenProvider.overrideWith(GuestToken.new)],
    );
    addTearDown(repositoryContainer.dispose);
    return repositoryContainer.read(animeInfoRepositoryProvider.notifier);
  }

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    cacheDirectory = await Directory.systemTemp.createTemp('anime_info_test_');
    Hive.init(cacheDirectory.path);
    Storage.animeInfoCache = await Hive.openBox<String>('anime_info_cache');
    Storage.subjectCommentsCache =
        await Hive.openBox<String>('subject_comments');
  });
  tearDownAll(() async {
    await Hive.close();
    await cacheDirectory.delete(recursive: true);
  });
  setUp(() async {
    await Storage.animeInfoCache.clear();
    await Storage.subjectCommentsCache.clear();
    remote = PendingAdapter();
    DioFactory.animeFlowDio.interceptors.clear();
    DioFactory.animeFlowDio.httpClientAdapter = remote;
    repository = createRepository();
  });
  tearDown(() {
    DioFactory.animeFlowDio.close(force: true);
    DioFactory.reset();
  });

  @Dependencies([AnimeInfo])
  ProviderContainer createContainer() {
    final container = ProviderContainer(
        parent: repositoryContainer,
        retry: (_, __) => null,
        overrides: [
          animeInfoArgsProvider
              .overrideWithValue(InfoRouteExtra(id: 42, name: '', image: '')),
        ]);
    addTearDown(container.dispose);
    container.listen(animeInfoProvider, (_, __) {});
    return container;
  }

  test('invalidation during first load completes the provider with fresh data',
      () async {
    final container = createContainer();
    final result = container.read(animeInfoProvider.future);
    await remote.waitForRequests(1);
    expect(remote.requests, hasLength(1));

    repositoryContainer.read(collectionRevisionProvider.notifier).changed();
    remote.requests[0].complete(reply(subject: subject('stale')));
    await remote.waitForRequests(2);
    expect(remote.requests, hasLength(2));
    expect(Storage.animeInfoCache.isEmpty, isTrue);
    expect(container.read(animeInfoProvider).isLoading, isTrue);

    remote.requests[1].complete(reply(subject: subject('fresh')));
    expect((await result).name, 'fresh');
    expect(container.read(animeInfoProvider).isLoading, isFalse);
    expect(local.read(42, sessionId: null)!.subject.name, 'fresh');
  });

  test('updating details leaves comments cache and provider untouched',
      () async {
    final container = createContainer();
    final initial = container.read(animeInfoProvider.future);
    await remote.waitForRequests(1);
    remote.requests.single.complete(reply(subject: subject('before')));
    await initial;
    await Storage.subjectCommentsCache.put('42:20:0', 'cached comments');

    final updated = subject('updated');
    container.read(animeInfoProvider.notifier).setAnimeInfo(updated);
    await repository.cacheSubject(updated, sessionId: null);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(animeInfoProvider).requireValue.name, 'updated');
    expect(Storage.subjectCommentsCache.get('42:20:0'), 'cached comments');
    expect(container.exists(subjectCommentsProvider), isFalse);
    expect(remote.requests, hasLength(1));
  });

  test('failure of an invalidated request retries; current failure is surfaced',
      () async {
    final container = createContainer();
    final result = container.read(animeInfoProvider.future);
    final assertion = expectLater(
        result,
        throwsA(isA<AnimeFlowApiException>().having(
            (error) => error.message, 'message', 'current request failed')));
    await remote.waitForRequests(1);

    repository.invalidateCache();
    remote.requests[0].complete(reply(error: 'obsolete request failed'));
    await remote.waitForRequests(2);
    expect(remote.requests, hasLength(2));
    remote.requests[1].complete(reply(error: 'current request failed'));
    await assertion;
    expect(container.read(animeInfoProvider).hasError, isTrue);
    expect(Storage.animeInfoCache.isEmpty, isTrue);
  });

  test('cancellation after invalidation does not start another request',
      () async {
    final token = CancelToken();
    final result = repository
        .watchSubject(42, sessionId: null, cancelToken: token)
        .toList();
    await remote.waitForRequests(1);
    repository.invalidateCache();
    token.cancel();
    remote.requests.single.complete(reply(subject: subject('stale')));

    expect(await result, isEmpty);
    expect(remote.requests, hasLength(1));
    expect(Storage.animeInfoCache.isEmpty, isTrue);
  });

  test('invalidation while caching retries before emitting the response',
      () async {
    final invalidated = Completer<void>();
    final subscription = Storage.animeInfoCache.watch().listen((event) {
      if (!event.deleted && !invalidated.isCompleted) {
        repository.invalidateCache();
        invalidated.complete();
      }
    });
    addTearDown(subscription.cancel);
    final result = repository.watchSubject(42, sessionId: null).toList();
    await remote.waitForRequests(1);
    remote.requests[0].complete(reply(subject: subject('stale')));
    await invalidated.future;
    await remote.waitForRequests(2);
    expect(remote.requests, hasLength(2));
    remote.requests[1].complete(reply(subject: subject('fresh')));

    expect((await result).map((item) => item.name), ['fresh']);
    expect(local.read(42, sessionId: null)!.subject.name, 'fresh');
  });

  test('fresh cache still avoids a network request', () async {
    await repository.cacheSubject(subject('cached'), sessionId: null);
    final result = await repository.watchSubject(42, sessionId: null).toList();
    expect(result.single.name, 'cached');
    expect(remote.requests, isEmpty);
  });

  test(
      'manual clearing does not let a pending subject response restore disk cache',
      () async {
    final result = repository.watchSubject(42, sessionId: null).toList();
    await remote.waitForRequests(1);
    await JsonResponseCache.clear(Storage.animeInfoCache);
    remote.requests.single.complete(reply(subject: subject('visible')));
    expect((await result).single.name, 'visible');
    expect(Storage.animeInfoCache.isEmpty, isTrue);
  });

  test('expired cache remains available if the current refresh fails',
      () async {
    await Storage.animeInfoCache.put(jsonEncode([null, 42]),
        jsonEncode({'subject': subject('cached').toJson(), 'cachedAt': 0}));
    final result = repository.watchSubject(42, sessionId: null).toList();
    await remote.waitForRequests(1);
    repository.invalidateCache();
    remote.requests[0].complete(reply(subject: subject('stale')));
    await remote.waitForRequests(2);
    expect(remote.requests, hasLength(2));
    remote.requests[1].complete(reply(error: 'offline'));

    expect((await result).map((item) => item.name), ['cached']);
    expect(Storage.animeInfoCache.isEmpty, isTrue);
  });
}

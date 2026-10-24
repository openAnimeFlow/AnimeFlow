import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/user/data/repository/user_profile_cache.dart';
import 'package:anime_flow/features/user/application/user_state_provider.dart';
import 'package:anime_flow/shared/models/flow/flow_users.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

FlowToken token(String session, {String access = 'access'}) => FlowToken(
      accessToken: access,
      refreshToken: 'refresh',
      tokenType: 'Bearer',
      expiresIn: 3600,
      refreshExpiresIn: 7200,
      sessionId: session,
    );

FlowUsers user(String name) => FlowUsers(
      id: 1,
      email: 'test@example.com',
      nickname: name,
      createTime: 1,
      avatar: '/avatar',
      background: '/background',
    );

class Tokens implements TokenRepository<FlowToken> {
  FlowToken? value = token('session-a');
  @override
  Future<FlowToken?> getToken() async => value;
  @override
  Future<void> saveToken(FlowToken token) async => value = token;
  @override
  Future<void> removeToken() async => value = null;
}

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

ResponseBody reply(String name, {int code = 200}) => ResponseBody.fromString(
      jsonEncode(
          {'code': code, 'message': 'offline', 'data': user(name).toJson()}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Adapter adapter;
  late Tokens tokens;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('user_profile_cache_');
    Hive.init(directory.path);
    Storage.userDataCache =
        await Hive.openBox<String>(StorageKey.userDataCacheKey);
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    await Storage.userDataCache.clear();
    tokens = Tokens();
    FlutterSecureStorage.setMockInitialValues({
      'flow_auth_token': jsonEncode(tokens.value!.toJson()),
    });
    adapter = Adapter()..respond = (_) => reply('fresh');
    DioFactory.animeFlowDio.interceptors.clear();
    DioFactory.animeFlowDio.httpClientAdapter = adapter;
  });
  tearDown(() {
    DioFactory.animeFlowDio.close(force: true);
    DioFactory.reset();
  });

  ProviderContainer container() {
    final c = ProviderContainer(retry: (_, __) => null, overrides: [
      flowTokenRepositoryProvider.overrideWithValue(tokens),
    ]);
    addTearDown(c.dispose);
    c.listen(currentUserInfoProvider, (_, __) {});
    return c;
  }

  Future<FlowUsers?> waitForName(ProviderContainer c, String name) {
    final done = Completer<FlowUsers?>();
    final sub = c.listen(currentUserInfoProvider, (_, next) {
      if (next.asData?.value?.nickname == name && !done.isCompleted) {
        done.complete(next.asData?.value);
      }
    }, fireImmediately: true);
    return done.future.whenComplete(sub.close);
  }

  test('cached profile is immediate, refreshed asynchronously and persisted',
      () async {
    await UserProfileCache.write('session-a', user('cached'));
    final pending = Completer<ResponseBody>();
    adapter.respond = (_) => pending.future;
    final c = container();
    expect((await c.read(currentUserInfoProvider.future))!.nickname, 'cached');
    await pumpEventQueue();
    expect(adapter.requests, hasLength(1));
    final updated = waitForName(c, 'fresh');
    pending.complete(reply('fresh'));
    await updated;
    await pumpEventQueue();
    expect(
        UserProfileCache.read('session-a')!.toJson(), user('fresh').toJson());
  });

  test('new provider reuses persisted profile and refreshes even fresh cache',
      () async {
    await container().read(currentUserInfoProvider.future);
    adapter.respond = (_) => reply('new');
    final reopened = container();
    expect((await reopened.read(currentUserInfoProvider.future))!.nickname,
        'fresh');
    await waitForName(reopened, 'new');
    expect(adapter.requests, hasLength(2));
  });

  test('background failure preserves data and cache', () async {
    await UserProfileCache.write('session-a', user('cached'));
    final before = Storage.userDataCache.toMap();
    adapter.respond = (_) => reply('', code: 500);
    final c = container();
    await c.read(currentUserInfoProvider.future);
    await pumpEventQueue();
    expect(c.read(currentUserInfoProvider).requireValue!.nickname, 'cached');
    expect(Storage.userDataCache.toMap(), before);
  });

  test('uncached failure remains an error', () async {
    adapter.respond = (_) => reply('', code: 500);
    final c = container();
    await expectLater(c.read(currentUserInfoProvider.future), throwsException);
    expect(c.read(currentUserInfoProvider).hasError, isTrue);
  });

  test('corrupt profile cache is repaired by network response', () async {
    await Storage.userDataCache.put(StorageKey.currentUserProfileKey, 'broken');
    await container().read(currentUserInfoProvider.future);
    expect(UserProfileCache.read('session-a')!.nickname, 'fresh');
  });

  test('another session cannot read previous profile', () async {
    await UserProfileCache.write('session-a', user('cached'));
    tokens.value = token('session-b');
    expect(UserProfileCache.read('session-b'), isNull);
    await container().read(currentUserInfoProvider.future);
    expect(UserProfileCache.read('session-a'), isNull);
    expect(UserProfileCache.read('session-b')!.nickname, 'fresh');
  });

  test('rotated access token retains cache for the same session', () async {
    await UserProfileCache.write('session-a', user('cached'));
    tokens.value = token('session-a', access: 'rotated');
    final c = container();
    expect((await c.read(currentUserInfoProvider.future))!.nickname, 'cached');
    await waitForName(c, 'fresh');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer rotated');
  });

  test('signed out build clears profile without fetching', () async {
    await UserProfileCache.write('session-a', user('cached'));
    tokens.value = null;
    expect(await container().read(currentUserInfoProvider.future), isNull);
    expect(Storage.userDataCache.get(StorageKey.currentUserProfileKey), isNull);
    expect(adapter.requests, isEmpty);
  });

  test('late response cannot overwrite a new session', () async {
    await UserProfileCache.write('session-a', user('cached'));
    final pending = Completer<ResponseBody>();
    adapter.respond = (_) => pending.future;
    final c = container();
    await c.read(currentUserInfoProvider.future);
    await pumpEventQueue();
    tokens.value = token('session-b');
    adapter.respond = (_) => reply('account-b');
    c.invalidate(currentFlowTokenProvider);
    await waitForName(c, 'account-b');
    pending.complete(reply('account-a'));
    await pumpEventQueue();
    expect(c.read(currentUserInfoProvider).requireValue!.nickname, 'account-b');
    expect(UserProfileCache.read('session-b')!.nickname, 'account-b');
  });

  test('count edits persist and supersede an older background request',
      () async {
    await UserProfileCache.write('session-a', user('cached'));
    final pending = Completer<ResponseBody>();
    adapter.respond = (_) => pending.future;
    final c = container();
    await c.read(currentUserInfoProvider.future);
    await pumpEventQueue();
    c.read(currentUserInfoProvider.notifier).moveCollectionCount(0, 3);
    await pumpEventQueue();
    pending.complete(reply('stale'));
    await pumpEventQueue();
    expect(c.read(currentUserInfoProvider).requireValue!.nickname, 'cached');
    expect(UserProfileCache.read('session-a')!.collectionCounts.watching, 1);
  });

  test('nickname updates persist and supersede an older refresh', () async {
    await UserProfileCache.write('session-a', user('cached'));
    final pending = Completer<ResponseBody>();
    adapter.respond = (options) async =>
        options.method == 'PUT' ? reply('edited') : await pending.future;
    final c = container();
    await c.read(currentUserInfoProvider.future);
    await pumpEventQueue();
    expect(
        await c.read(currentUserInfoProvider.notifier).updateNickname('edited'),
        isNull);
    pending.complete(reply('stale'));
    await pumpEventQueue();
    expect(c.read(currentUserInfoProvider).requireValue!.nickname, 'edited');
    expect(UserProfileCache.read('session-a')!.nickname, 'edited');
  });

  test('disposing during refresh prevents a late cache write', () async {
    await UserProfileCache.write('session-a', user('cached'));
    final pending = Completer<ResponseBody>();
    adapter.respond = (_) => pending.future;
    final c = ProviderContainer(overrides: [
      flowTokenRepositoryProvider.overrideWithValue(tokens),
    ]);
    c.listen(currentUserInfoProvider, (_, __) {});
    await c.read(currentUserInfoProvider.future);
    await pumpEventQueue();
    c.dispose();
    pending.complete(reply('late'));
    await pumpEventQueue();
    expect(UserProfileCache.read('session-a')!.nickname, 'cached');
  });

  test('logout clears cache and rejects a pending refresh', () async {
    await UserProfileCache.write('session-a', user('cached'));
    final pending = Completer<ResponseBody>();
    adapter.respond = (_) => pending.future;
    final c = container();
    await c.read(currentUserInfoProvider.future);
    await pumpEventQueue();
    tokens.value = null;
    final invalidateSession =
        Provider<void Function()>((ref) => () => invalidateAuthSession(ref));
    c.read(invalidateSession)();
    expect(await c.read(currentUserInfoProvider.future), isNull);
    pending.complete(reply('late'));
    await pumpEventQueue();
    expect(c.read(currentUserInfoProvider).requireValue, isNull);
    expect(Storage.userDataCache.get(StorageKey.currentUserProfileKey), isNull);
  });

  test('avatar and background updates write the returned profile to cache',
      () async {
    final c = container();
    await c.read(currentUserInfoProvider.future);
    final notifier = c.read(currentUserInfoProvider.notifier);
    adapter.respond = (_) => reply('avatar-updated');
    expect(await notifier.uploadAvatar(Uint8List.fromList([1, 2, 3])), isNull);
    expect(UserProfileCache.read('session-a')!.nickname, 'avatar-updated');
    adapter.respond = (_) => reply('background-updated');
    expect(await notifier.updateBackground(10), isNull);
    expect(UserProfileCache.read('session-a')!.nickname, 'background-updated');
  });
}

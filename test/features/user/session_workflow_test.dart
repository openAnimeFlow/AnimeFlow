import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/auth/repository/flow_token_storage.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/network/interceptors/flow_refresh_token_interceptor.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/auth/application/login_provider.dart';
import 'package:anime_flow/features/auth/application/login_service.dart';
import 'package:anime_flow/features/auth/application/oauth_notice_provider.dart';
import 'package:anime_flow/features/user/application/collection_revision_provider.dart';
import 'package:anime_flow/features/user/application/user_collection_provider.dart';
import 'package:anime_flow/features/user/data/repository/collection_sync_repository.dart';
import 'package:anime_flow/features/user/user_api.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

FlowToken token(String session) => FlowToken(
    accessToken: session,
    refreshToken: session,
    tokenType: 'Bearer',
    expiresIn: 3600,
    refreshExpiresIn: 86400,
    sessionId: session);

class ApiAdapter implements HttpClientAdapter {
  bool bound = true;
  int profileReads = 0;
  final requests = <RequestOptions>[];
  Completer<ResponseBody>? profileUpdate;
  final updateStarted = Completer<void>();
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    if (options.path == AnimeFlowApi.flowUsers &&
        options.method == 'PUT' &&
        profileUpdate != null) {
      updateStarted.complete();
      return profileUpdate!.future;
    }
    final Object data;
    if (options.path == AnimeFlowApi.bangumiBind ||
        options.path == AnimeFlowApi.bangumiBindPost ||
        options.path == AnimeFlowApi.bangumiUnbind) {
      if (options.path == AnimeFlowApi.bangumiUnbind) bound = false;
      if (options.path == AnimeFlowApi.bangumiBindPost) bound = true;
      data = {'bound': bound, 'platformUid': 1};
    } else if (options.path == AnimeFlowApi.bangumiLogin) {
      data = token('oauth').toJson();
    } else {
      profileReads++;
      data = {'id': 1, 'nickname': 'User', 'createTime': 0};
    }
    return ResponseBody.fromString(jsonEncode({'code': 200, 'data': data}), 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
  }

  @override
  void close({bool force = false}) {}
}

class SyncRepository extends CollectionSyncRepository {
  final tokens = <CancelToken>[];
  final streams = <StreamController<BgmCollectionSyncStatusItem?>>[];
  int starts = 0;
  BgmCollectionSyncStatusItem statusValue =
      const BgmCollectionSyncStatusItem(status: BgmCollectionSyncStatus.idle);
  Completer<BgmCollectionSyncStatusItem>? pendingTrigger;

  @override
  Future<BgmCollectionSyncStatusItem> status() async => statusValue;
  @override
  Future<BgmCollectionSyncStatusItem> trigger(int type, String key) async {
    starts++;
    return pendingTrigger!.future;
  }

  @override
  Stream<BgmCollectionSyncStatusItem?> events(CancelToken cancelToken) {
    final stream = StreamController<BgmCollectionSyncStatusItem?>();
    tokens.add(cancelToken);
    streams.add(stream);
    return stream.stream;
  }

  Future<void> close() async {
    for (final stream in streams) {
      await stream.close();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ApiAdapter api;
  late SyncRepository sync;
  late ProviderContainer container;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('session_workflow_');
    Hive.init(directory.path);
    Storage.setting = await Hive.openBox<dynamic>('session_settings');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await FlowTokenStorage.instance.saveToken(token('first'));
    api = ApiAdapter();
    DioFactory.animeFlowDio.interceptors.clear();
    DioFactory.animeFlowDio.httpClientAdapter = api;
    sync = SyncRepository();
    container = ProviderContainer(retry: (_, __) => null, overrides: [
      collectionSyncRepositoryProvider.overrideWithValue(sync),
      collectionPageLoaderProvider.overrideWithValue((
              {required type, required offset, required sort, keyword}) async =>
          UserCollectionsItem(data: [], total: 0)),
      loginServiceProvider.overrideWithValue(LoginService(
          emailLogin: (
                  {required email,
                  required password,
                  required platform}) async =>
              token('second'))),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await sync.close();
    DioFactory.animeFlowDio.close(force: true);
    DioFactory.reset();
    FlowRefreshTokenInterceptor.onSessionExpired = null;
    FlowRefreshTokenInterceptor.onTokenRefreshed = null;
  });

  test('email login changes identity and clears previous collections',
      () async {
    await container.read(userCollectionsProvider.notifier).loadInitial(1);
    expect(await container.read(currentFlowTokenProvider.future), isNotNull);
    await container.read(emailLoginProvider)(
        email: 'user@test', password: 'secret');
    expect((await container.read(currentFlowTokenProvider.future))?.sessionId,
        'second');
    expect(container.read(authSessionRevisionProvider), 1);
    expect(container.read(userCollectionsProvider).tabs, isEmpty);
  });

  test('token renewal preserves collection pages and session revision',
      () async {
    await container.read(currentFlowTokenProvider.future);
    await container.read(userCollectionsProvider.notifier).loadInitial(1);
    final pages = container.read(userCollectionsProvider);
    await FlowTokenStorage.instance.saveToken(token('first'));
    FlowRefreshTokenInterceptor.onTokenRefreshed!();
    await container.read(currentFlowTokenProvider.future);
    expect(container.read(userCollectionsProvider), same(pages));
    expect(container.read(authSessionRevisionProvider), 0);
  });

  test('a profile edit finishing after logout cannot restore the previous user',
      () async {
    await container.read(currentUserInfoProvider.future);
    api.profileUpdate = Completer<ResponseBody>();
    final pending = container
        .read(currentUserInfoProvider.notifier)
        .updateNickname('Changed');
    await api.updateStarted.future;
    await container
        .read(accountControllerProvider.notifier)
        .clearUserInfo(notifyServer: false);
    expect(await container.read(currentUserInfoProvider.future), isNull);
    api.profileUpdate!.complete(ResponseBody.fromString(
        jsonEncode({
          'code': 200,
          'data': {'id': 1, 'nickname': 'Changed', 'createTime': 0},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        }));
    expect(await pending, '用户会话已变更');
    expect(container.read(currentUserInfoProvider).value, isNull);
  });

  test('logout stops SSE and ignores an old trigger result', () async {
    await container.read(bgmCollectionSyncProvider.future);
    final notifier = container.read(bgmCollectionSyncProvider.notifier);
    notifier.setPageSubscription(Object(), true);
    sync.pendingTrigger = Completer<BgmCollectionSyncStatusItem>();
    final pending = notifier.triggerSync();
    await container
        .read(accountControllerProvider.notifier)
        .clearUserInfo(notifyServer: false);
    expect(sync.tokens.single.isCancelled, isTrue);
    expect(await container.read(bgmCollectionSyncProvider.future), isNull);
    sync.pendingTrigger!.complete(const BgmCollectionSyncStatusItem(
        status: BgmCollectionSyncStatus.success, taskId: 9, syncedCount: 5));
    await pending;
    expect(container.read(bgmCollectionSyncProvider).value, isNull);
    expect(container.read(collectionRevisionProvider), 0);
    expect(await container.read(currentUserInfoProvider.future), isNull);
    expect(await container.read(bangumiBindProvider.future), isNull);
  });

  test(
      'unbinding cancels sync; binding callback restores discovery without starting a task',
      () async {
    await container.read(bgmCollectionSyncProvider.future);
    final notifier = container.read(bgmCollectionSyncProvider.notifier);
    notifier.setPageSubscription(Object(), true);
    final oauth = container.read(userOAuthControllerProvider.notifier);
    await oauth.unbindBangumi();
    expect(sync.tokens.first.isCancelled, isTrue);
    expect(await container.read(bgmCollectionSyncProvider.future), isNull);
    final result = await oauth
        .handleDeepLink('flow://auth/callback?code=bind&purpose=bind');
    expect(result.success, isTrue);
    expect(await container.read(bgmCollectionSyncProvider.future), isNotNull);
    expect(sync.tokens.length, 2);
    expect(sync.starts, 0);
    expect(container.read(oauthNoticeProvider)?.message, contains('绑定成功'));
  });

  test('sync refreshes real profile and pages once per changed progress',
      () async {
    await container.read(bgmCollectionSyncProvider.future);
    await container.read(currentUserInfoProvider.future);
    await container.read(userCollectionsProvider.notifier).loadInitial(1);
    final reads = api.profileReads;
    sync.statusValue = const BgmCollectionSyncStatusItem(
        status: BgmCollectionSyncStatus.success, taskId: 1, syncedCount: 5);
    await container.read(bgmCollectionSyncProvider.notifier).refreshStatus();
    expect(container.read(userCollectionsProvider).tabs, isEmpty);
    await container.read(currentUserInfoProvider.future);
    expect(api.profileReads, reads + 1);
    await container.read(userCollectionsProvider.notifier).loadInitial(1);
    final pages = container.read(userCollectionsProvider);
    await container.read(bgmCollectionSyncProvider.notifier).refreshStatus();
    expect(container.read(userCollectionsProvider), same(pages));
    expect(container.read(collectionRevisionProvider), 1);
  });

  test(
      'leaving a page and backgrounding cancel SSE; resume restores one connection',
      () async {
    await container.read(bgmCollectionSyncProvider.future);
    final notifier = container.read(bgmCollectionSyncProvider.notifier);
    final owner = Object();
    notifier.setPageSubscription(owner, true);
    notifier.setForeground(false);
    expect(sync.tokens.single.isCancelled, isTrue);
    notifier.setForeground(true);
    notifier.setForeground(true);
    expect(sync.tokens.length, 2);
    notifier.setPageSubscription(owner, false);
    expect(sync.tokens.every((token) => token.isCancelled), isTrue);
    expect(sync.starts, 0);
  });
}

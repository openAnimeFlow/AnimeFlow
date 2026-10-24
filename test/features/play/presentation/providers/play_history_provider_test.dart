import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/auth/repository/flow_token_storage.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/play/presentation/providers/play_history_provider.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

class _HistoryAdapter implements HttpClientAdapter {
  final firstRequest = Completer<void>();
  var requests = 0;
  var fail = true;
  Completer<ResponseBody>? pending;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests++;
    if (!firstRequest.isCompleted) firstRequest.complete();
    if (pending != null) return pending!.future;
    return ResponseBody.fromString(
        fail
            ? '{"code":500,"message":"同步服务不可用","data":null}'
            : '{"code":200,"message":"","data":[]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late _HistoryAdapter adapter;
  final token = FlowToken(
    accessToken: 'access',
    refreshToken: 'refresh',
    tokenType: 'Bearer',
    expiresIn: 3600,
    refreshExpiresIn: 604800,
    sessionId: 'history-test',
  );

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('play_history_provider_');
    Hive.init(directory.path);
    Hive.registerAdapter(PlayHistoryAdapter());
    Storage.playHistory = await Hive.openBox<PlayHistory>('play_history');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await FlowTokenStorage.instance.saveToken(token);
    await Storage.playHistory.clear();
    await Storage.playHistory.put(
        42,
        PlayHistory(
          subjectId: 42,
          episodeId: 7,
          episodeSort: 1,
          subjectName: '本地记录',
          cover: '',
          updateAt: DateTime(2026),
          position: 60,
          duration: 600,
          alias: [],
          isSyncedToServer: true,
        ));
    adapter = _HistoryAdapter();
    DioFactory.animeFlowDio.interceptors.clear();
    DioFactory.animeFlowDio.httpClientAdapter = adapter;
  });
  tearDown(() {
    DioFactory.animeFlowDio.close(force: true);
    DioFactory.reset();
  });

  test(
      'failed auto sync preserves local records and a later success clears the error',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final failed = Completer<void>();
    container.listen(playHistoryProvider, (_, next) {
      if (next.value?.syncError != null && !failed.isCompleted) {
        failed.complete();
      }
    });
    final initial = await container.read(playHistoryProvider.future);
    expect(initial.records.single.subjectId, 42);
    await failed.future.timeout(const Duration(seconds: 10));
    final state = container.read(playHistoryProvider).requireValue;
    expect(state.records.single.subjectId, 42);
    expect(state.syncError.toString(), contains('同步服务不可用'));
    expect(adapter.requests, 3);

    // 等待当前自动同步完成，再手动重试，避免复用尚未结束的去重操作。
    await pumpEventQueue();
    adapter.fail = false;
    await container.read(playHistoryProvider.notifier).syncFromServer();
    final refreshed = container.read(playHistoryProvider).requireValue;
    expect(refreshed.syncError, isNull);
    expect(refreshed.records.single.subjectId, 42);
    expect(adapter.requests, 4);
  });

  test('disposing during sync prevents retries and disposed-state updates',
      () async {
    final pending = adapter.pending = Completer<ResponseBody>();
    final container = ProviderContainer();
    container.listen(playHistoryProvider, (_, __) {});
    await container.read(playHistoryProvider.future);
    await adapter.firstRequest.future;
    container.dispose();
    pending.complete(ResponseBody.fromString(
      '{"code":500,"message":"late error","data":null}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    ));
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    expect(adapter.requests, 1);
  });
}

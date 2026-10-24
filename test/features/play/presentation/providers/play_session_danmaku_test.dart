import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/auth/repository/flow_token_storage.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/danmaku_canvas.dart';
import 'package:anime_flow/features/play/application/danmaku_session.dart';
import 'package:anime_flow/features/play/application/danmaku_state.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sending local danmaku through v2', () {
    late _DanmakuAdapter adapter;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      DioFactory.reset();
      adapter = _DanmakuAdapter();
      final dio = DioFactory.animeFlowDio;
      dio.interceptors.clear();
      dio.httpClientAdapter = adapter;
      await FlowTokenStorage.instance.saveToken(FlowToken(
        accessToken: 'flow-access-token',
        refreshToken: 'flow-refresh-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
        refreshExpiresIn: 604800,
        sessionId: 'test-session',
      ));
    });

    tearDown(DioFactory.reset);

    test('sends one request with the real Bangumi episode ID', () async {
      final canvas = _Canvas();
      final session = _session(_Store(), DanmakuChineseConverter(), userId: 42)
        ..canvas = canvas;
      addTearDown(session.dispose);
      session.setPlaybackContext(
        subjectId: 70131,
        episodeId: 260269,
        isLocalPlayback: false,
      );

      expect(
        await session.send(' hello ', type: 5, color: 0xff123456),
        isTrue,
      );

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/api/danmaku');
      expect(request.headers['X-Api-Version'], '2');
      expect(request.headers['Authorization'], 'Bearer flow-access-token');
      expect(request.data, {
        'subjectId': 70131,
        'episodeId': 260269,
        'comment': 'hello',
        'time': 0.0,
        'type': 5,
        'color': 0x123456,
      });
      expect(canvas.lastDanmaku?.bgmUserId, 42);
      expect(canvas.lastCurrentUserId, 42);
    });

    test('does not send when Bangumi playback IDs are missing', () async {
      final session = _session(_Store(), DanmakuChineseConverter());
      addTearDown(session.dispose);

      for (final ids in [(0, 260269), (70131, 0)]) {
        session.setPlaybackContext(
          subjectId: ids.$1,
          episodeId: ids.$2,
          isLocalPlayback: false,
        );
        expect(await session.send('hello'), isFalse);
      }

      expect(adapter.requests, isEmpty);
    });
  });

  group('loading merged danmaku through v2', () {
    late _DanmakuAdapter adapter;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      DioFactory.reset();
      adapter = _DanmakuAdapter();
      final dio = DioFactory.animeFlowDio;
      dio.interceptors.clear();
      dio.httpClientAdapter = adapter;
    });

    tearDown(DioFactory.reset);

    test('loads upstream and local comments in one anonymous request',
        () async {
      adapter.respond = (_) async => '''
        {"code":200,"message":"成功","data":{"count":2,"comments":[
          {"cid":1,"m":"upstream","p":"12.5,1,16777215,[BiliBili]"},
          {"cid":2,"m":"local","p":"1.25,5,16777215,[AnimeFlow],5000000001"}
        ]}}
      ''';
      final store = _Store();
      final session = _session(store, DanmakuChineseConverter());
      addTearDown(session.dispose);

      await _loadOnline(session);

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, '/api/danmaku');
      expect(request.headers['X-Api-Version'], '2');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.queryParameters['withRelated'], 'true');
      expect(request.queryParameters['subjectId'], 70131);
      expect(request.queryParameters['episodeId'], 260269);
      expect(store.value.danmakus[12]?.single.message, 'upstream');
      expect(store.value.danmakus[1]?.single.message, 'local');
      expect(store.value.danmakus[1]?.single.bgmUserId, 5000000001);
      expect(store.value.loadStatus, DanmakuLoadStatus.idle);
    });

    test('empty comments finish loading without installing danmaku', () async {
      adapter.respond = (_) async =>
          '{"code":200,"message":"成功","data":{"count":0,"comments":[]}}';
      final store = _Store();
      final session = _session(store, DanmakuChineseConverter());
      addTearDown(session.dispose);

      await _loadOnline(session);

      expect(store.installs, 0);
      expect(store.value.loadStatus, DanmakuLoadStatus.idle);
    });

    test('playback change discards a pending v2 response', () async {
      final started = Completer<void>();
      final response = Completer<String>();
      adapter.respond = (_) {
        started.complete();
        return response.future;
      };
      final store = _Store();
      final session = _session(store, DanmakuChineseConverter());
      addTearDown(session.dispose);

      final loading = _loadOnline(session);
      await started.future;
      session.beginPlaybackChange();
      response.complete(
        '{"code":200,"message":"成功","data":{"count":1,"comments":'
        '[{"m":"stale","p":"1,1,16777215,[AnimeFlow],42"}]}}',
      );
      await loading;

      expect(store.installs, 0);
      expect(store.value.loadStatus, DanmakuLoadStatus.waitingForVideo);
    });
  });

  test('seeking clears the danmaku canvas', () {
    final canvas = _Canvas();
    final session = _session(_Store(), DanmakuChineseConverter())
      ..canvas = canvas;
    addTearDown(session.dispose);

    session.onSeek();

    expect(canvas.clears, 1);
  });

  test('new episode rejects an older pending conversion', () async {
    final file = await _danmakuFile();
    final converter = _Converter();
    final store = _Store();
    final session = _session(store, converter);
    addTearDown(session.dispose);

    session.beginPlaybackChange();
    session.clear();
    final first = _load(session, file.path);
    await converter.started.future;
    expect(
        store.statuses,
        containsAllInOrder([
          DanmakuLoadStatus.waitingForVideo,
          DanmakuLoadStatus.loading,
        ]));

    session.beginPlaybackChange();
    session.clear();
    await _load(session, file.path);
    expect(converter.calls, 2);
    expect(store.installs, 1);
    expect(store.value.loadStatus, DanmakuLoadStatus.idle);
    final statusCount = store.statuses.length;

    converter.gate.complete();
    await first;
    expect(store.installs, 1);
    expect(store.statuses.length, statusCount);
  });

  test('stopping during conversion discards the pending result', () async {
    final file = await _danmakuFile();
    final converter = _Converter();
    final store = _Store();
    final session = _session(store, converter);
    addTearDown(session.dispose);

    session.beginPlaybackChange();
    session.clear();
    final loading = _load(session, file.path);
    await converter.started.future;
    session.beginPlaybackChange();
    session.clear();
    final statusCount = store.statuses.length;

    converter.gate.complete();
    await loading;
    expect(store.installs, 0);
    expect(store.value.loadStatus, DanmakuLoadStatus.waitingForVideo);
    expect(store.statuses.length, statusCount);
  });
}

Future<File> _danmakuFile() async {
  final directory =
      await Directory.systemTemp.createTemp('danmaku_session_test');
  addTearDown(() => directory.delete(recursive: true));
  final file = File('${directory.path}/danmaku.json');
  await file.writeAsString('[{"m":"test","p":"1,1,16777215,test"}]');
  return file;
}

DanmakuSession _session(
  _Store store,
  DanmakuChineseConverter converter, {
  int? userId,
}) =>
    DanmakuSession(
      store: store,
      converter: converter,
      initialChineseMode: DanmakuChineseMode.none,
      readPlayback: () => const DanmakuPlaybackSnapshot(
        position: Duration.zero,
        duration: Duration.zero,
        playing: false,
      ),
      currentUserId: () => userId,
    );

Future<void> _load(DanmakuSession session, String path) => session.loadEpisode(
      subjectId: 1,
      episodeId: 1,
      isLocalPlayback: true,
      localPath: path,
      expectedRequestId: session.requestId,
      isPlaybackCurrent: () => true,
    );

Future<void> _loadOnline(DanmakuSession session) => session.loadEpisode(
      subjectId: 70131,
      episodeId: 260269,
      isLocalPlayback: false,
      localPath: null,
      expectedRequestId: session.requestId,
      isPlaybackCurrent: () => true,
    );

class _Converter extends DanmakuChineseConverter {
  final started = Completer<void>();
  final gate = Completer<void>();
  int calls = 0;

  @override
  Future<List<Danmaku>> convertDanmakus(
      List<Danmaku> items, DanmakuChineseMode mode) async {
    if (++calls == 1) {
      started.complete();
      await gate.future;
    }
    return items;
  }
}

class _Store implements DanmakuStore {
  DanmakuState _state = const DanmakuState();
  final statuses = <DanmakuLoadStatus>[];
  int installs = 0;

  @override
  DanmakuState get value => _state;

  @override
  void setLoadStatus(DanmakuLoadStatus value) {
    statuses.add(value);
    _state = _state.copyWith(loadStatus: value);
  }

  @override
  void setDanmakus(Map<int, List<Danmaku>> value) {
    installs++;
    _state = _state.copyWith(danmakus: value);
  }

  @override
  void clearDanmakus() => _state = _state.copyWith(danmakus: const {});

  @override
  void incrementEpoch() => _state = _state.copyWith(epoch: _state.epoch + 1);

  @override
  void setHiddenPlatforms(Set<String> value) =>
      _state = _state.copyWith(hiddenPlatforms: value);

  @override
  void toggleEnabled() => _state = _state.copyWith(enabled: !_state.enabled);

  @override
  void toggleHiddenPlatform(String platform) {
    final next = {..._state.hiddenPlatforms};
    if (!next.remove(platform)) next.add(platform);
    _state = _state.copyWith(hiddenPlatforms: next);
  }
}

class _Canvas implements DanmakuCanvas {
  int clears = 0;
  Danmaku? lastDanmaku;
  int? lastCurrentUserId;

  @override
  void addDanmaku(Danmaku danmaku, int? currentUserId, {int? color}) {
    lastDanmaku = danmaku;
    lastCurrentUserId = currentUserId;
  }

  @override
  void clear() => clears++;

  @override
  void syncPlayback(bool playing) {}
}

class _DanmakuAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Future<String> Function(RequestOptions)? respond;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final handler = respond;
    return ResponseBody.fromString(
      handler == null
          ? '{"code":200,"message":"成功","data":"success"}'
          : await handler(options),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

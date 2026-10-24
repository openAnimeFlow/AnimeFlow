import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/calendar/calendar_api.dart';
import 'package:anime_flow/shared/models/bangumi/calendar_item.dart';
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

Map<String, dynamic> calendarJson(int id) => {
      'year': 2026,
      'month': 10,
      'seasonName': '秋季',
      'total': 1,
      '1': [
        {
          'subject': {
            'id': id,
            'name': 'Anime $id',
            'nameCN': '动画$id',
            'type': 2,
            'info': 'TV',
            'metaTags': [' TV ', '冒险', 'TV', ' '],
            'locked': false,
            'nsfw': false,
            'rating': {
              'rank': 1,
              'count': List.filled(10, 0),
              'score': 8,
              'total': 10
            },
          },
          'watchers': 100,
          'episodeCount': 12,
          'latestEpisode': {
            'id': 10,
            'sort': 1,
            'name': 'Episode 1',
            'nameCn': '第一集',
            'airdate': '2026-10-05',
            'duration': '24m'
          },
          'nextEpisode': {
            'id': 11,
            'sort': 2,
            'name': 'Episode 2',
            'nameCn': '第二集',
            'airdate': '2026-10-12',
            'duration': '24m'
          },
        },
      ],
      '7': [],
    };

ResponseBody reply(Object? data, {int code = 200}) => ResponseBody.fromString(
      jsonEncode({'code': code, 'message': 'offline', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );

String currentKey(DateTime date) =>
    'current:${date.year}:${date.month}:${date.day}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Adapter adapter;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('calendar_cache_test_');
    Hive.init(directory.path);
    Storage.calendarCache = await Hive.openBox<String>('calendar');
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    await Storage.calendarCache.clear();
    adapter = Adapter()..respond = (_) => reply(calendarJson(1));
    DioFactory.animeFlowDio.interceptors.clear();
    DioFactory.animeFlowDio.httpClientAdapter = adapter;
  });
  tearDown(() {
    DioFactory.animeFlowDio.close(force: true);
    DioFactory.reset();
  });

  ProviderContainer container({CalendarSeason? season}) {
    final c = ProviderContainer(retry: (_, __) => null);
    addTearDown(c.dispose);
    c.listen(calendarProvider(season), (_, __) {});
    return c;
  }

  Future<void> cache(String key, int id, {Duration age = Duration.zero}) =>
      Storage.calendarCache.put(
          key,
          jsonEncode({
            'cachedAt': DateTime.now().subtract(age).millisecondsSinceEpoch,
            'data': calendarJson(id),
          }));

  Future<CalendarWithTags> waitForId(ProviderContainer c, int id) {
    final done = Completer<CalendarWithTags>();
    final subscription = c.listen(calendarProvider(null), (_, next) {
      final value = next.asData?.value;
      if (value?.calendar.calendarData['1']?.single.subject.id == id &&
          !done.isCompleted) {
        done.complete(value);
      }
    }, fireImmediately: true);
    return done.future.whenComplete(subscription.close);
  }

  test('reopening reuses full weekly data, episode fields and normalized tags',
      () async {
    final first = container();
    final initial = await first.read(calendarProvider(null).future);
    final reopened = container();
    final cached = await reopened.read(calendarProvider(null).future);
    expect(adapter.requests, hasLength(1));
    expect(
        cached.calendar.toJson(), Calendar.fromJson(calendarJson(1)).toJson());
    expect(cached.calendar.toJson(), initial.calendar.toJson());
    expect(cached.tags, ['TV', '冒险']);
    expect(() => cached.tags.add('test'), throwsUnsupportedError);
    expect(adapter.requests.single.queryParameters, isEmpty);
  });

  test('expired cache is emitted immediately and then replaced by fresh data',
      () async {
    await cache(currentKey(DateTime.now()), 1, age: const Duration(hours: 13));
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    adapter.respond = (_) {
      started.complete();
      return pending.future;
    };
    final c = container();
    expect(
        (await c.read(calendarProvider(null).future))
            .calendar
            .calendarData['1']!
            .single
            .subject
            .id,
        1);
    await started.future;
    final update = waitForId(c, 2);
    pending.complete(reply(calendarJson(2)));
    expect((await update).calendar.calendarData['1']!.single.subject.id, 2);
    expect(
        jsonDecode(Storage.calendarCache.get(currentKey(DateTime.now()))!)[
            'data']['1'][0]['subject']['id'],
        2);
  });

  test('failed background refresh retains stale data without renewing expiry',
      () async {
    await cache(currentKey(DateTime.now()), 1, age: const Duration(hours: 13));
    final before = Storage.calendarCache.toMap();
    adapter.respond = (_) => reply(null, code: 500);
    final c = container();
    await c.read(calendarProvider(null).future);
    await pumpEventQueue();
    expect(adapter.requests, hasLength(1));
    expect(
        c
            .read(calendarProvider(null))
            .requireValue
            .calendar
            .calendarData['1']!
            .single
            .subject
            .id,
        1);
    expect(Storage.calendarCache.toMap(), before);
  });

  test(
      'explicit invalidation bypasses fresh cache and cancels an older refresh',
      () async {
    await cache(currentKey(DateTime.now()), 1);
    final c = container();
    await c.read(calendarProvider(null).future);
    expect(adapter.requests, isEmpty);
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    adapter.respond = (_) {
      started.complete();
      return pending.future;
    };
    c.invalidate(calendarProvider(null));
    await started.future;
    final oldToken = adapter.requests.single.cancelToken!;
    adapter.respond = (_) => reply(calendarJson(3));
    final update = waitForId(c, 3);
    c.invalidate(calendarProvider(null));
    await update;
    expect(oldToken.isCancelled, isTrue);
    pending.complete(reply(calendarJson(2)));
    await pumpEventQueue();
    expect(
        c
            .read(calendarProvider(null))
            .requireValue
            .calendar
            .calendarData['1']!
            .single
            .subject
            .id,
        3);
    expect(
        jsonDecode(Storage.calendarCache.get(currentKey(DateTime.now()))!)[
            'data']['1'][0]['subject']['id'],
        3);
  });

  test('current dates and explicit seasons have separate cache entries',
      () async {
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    await cache(currentKey(yesterday), 99);
    final current = container();
    expect(
        (await current.read(calendarProvider(null).future))
            .calendar
            .calendarData['1']!
            .single
            .subject
            .id,
        1);
    const spring = (year: 2026, month: 4);
    const autumn = (year: 2026, month: 10);
    final springContainer = container(season: spring);
    await springContainer.read(calendarProvider(spring).future);
    final autumnContainer = container(season: autumn);
    await autumnContainer.read(calendarProvider(autumn).future);
    await container(season: spring).read(calendarProvider(spring).future);
    expect(adapter.requests, hasLength(3));
    expect(adapter.requests[1].queryParameters, {'year': 2026, 'month': 4});
    expect(adapter.requests[2].queryParameters, {'year': 2026, 'month': 10});
    expect(Storage.calendarCache.length, 4);
  });

  test('disposing the last listener cancels refresh and prevents late writes',
      () async {
    final pending = Completer<ResponseBody>();
    final started = Completer<void>();
    adapter.respond = (_) {
      started.complete();
      return pending.future;
    };
    final c = ProviderContainer(retry: (_, __) => null);
    addTearDown(c.dispose);
    final subscription = c.listen(calendarProvider(null), (_, __) {});
    await started.future;
    subscription.close();
    await c.pump();
    expect(adapter.requests.single.cancelToken!.isCancelled, isTrue);
    pending.complete(reply(calendarJson(1)));
    await pumpEventQueue();
    expect(Storage.calendarCache.isEmpty, isTrue);
  });

  test(
      'corrupt cache is replaced, while uncached network failures remain errors',
      () async {
    await Storage.calendarCache.put(currentKey(DateTime.now()), 'broken');
    final c = container();
    await c.read(calendarProvider(null).future);
    expect(
        jsonDecode(Storage.calendarCache.get(currentKey(DateTime.now()))!)[
            'data']['total'],
        1);
    adapter.respond = (_) => reply(null, code: 500);
    const other = (year: 2025, month: 1);
    final failed = container(season: other);
    await expectLater(
        failed.read(calendarProvider(other).future), throwsException);
    expect(failed.read(calendarProvider(other)).hasError, isTrue);
  });
}

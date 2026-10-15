import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/network/flow/flow_http_client_adapter.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter(this.respond);
  final Future<ResponseBody> Function() respond;
  final closes = <bool>[];
  int requests = 0;
  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) {
    requests++;
    return respond();
  }

  @override
  void close({bool force = false}) => closes.add(force);
}

void main() {
  test('route change drains an old SSE pool while new fetches use a new pool',
      () async {
    final pool = FlowEndpointPool();
    final chunks = StreamController<Uint8List>();
    final children = <RecordingAdapter>[];
    final adapter = FlowHttpClientAdapter(
        pool: pool,
        createAdapter: (addresses, generation) {
          final child = RecordingAdapter(() async => children.length == 1
              ? ResponseBody(chunks.stream, 200)
              : ResponseBody.fromString('new', 200));
          children.add(child);
          return child;
        });
    addTearDown(() {
      adapter.close(force: true);
      pool.dispose();
    });
    final options = RequestOptions(path: 'https://ligg.top/events');
    final oldResponse = await adapter.fetch(options, null, null);
    final events = <Uint8List>[];
    final subscription = oldResponse.stream.listen(events.add);
    pool.networkChanged();
    expect(children.single.closes, [false]);
    final newResponse = await adapter.fetch(options, null, null);
    await newResponse.stream.drain<void>();
    expect(children, hasLength(2));
    chunks.add(Uint8List.fromList([1]));
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1));
    expect(children.first.closes, [false]);
    await subscription.cancel();
    await chunks.close();
  });

  test('retiring a generation does not close its pending header acquisition',
      () async {
    final pool = FlowEndpointPool();
    final pending = Completer<ResponseBody>();
    final child = RecordingAdapter(() => pending.future);
    final adapter = FlowHttpClientAdapter(
        pool: pool, createAdapter: (addresses, generation) => child);
    addTearDown(() {
      adapter.close(force: true);
      pool.dispose();
    });
    final request =
        adapter.fetch(RequestOptions(path: 'https://ligg.top/'), null, null);
    pool.networkChanged();
    expect(child.closes, isEmpty);
    pending.complete(ResponseBody.fromString('completed', 200));
    final response = await request;
    expect(child.closes, [false]);
    await response.stream.drain<void>();
  });

  test('HTTP errors do not replay POST bodies', () async {
    final pool = FlowEndpointPool();
    final child = RecordingAdapter(
        () async => throw const SocketException('closed after write'));
    final adapter = FlowHttpClientAdapter(
        pool: pool, createAdapter: (addresses, generation) => child);
    addTearDown(() {
      adapter.close(force: true);
      pool.dispose();
    });
    await expectLater(
        adapter.fetch(
            RequestOptions(path: 'https://ligg.top/write', method: 'POST'),
            Stream.value(Uint8List.fromList([1, 2, 3])),
            null),
        throwsA(isA<SocketException>()));
    expect(child.requests, 1);
  });

  test('already cancelled token cancels acquisition before a request exists',
      () async {
    final pool = FlowEndpointPool();
    final adapter = FlowHttpClientAdapter(pool: pool);
    addTearDown(() {
      adapter.close(force: true);
      pool.dispose();
    });
    final cancel = Completer<void>()..complete();
    final result = adapter.fetch(
        RequestOptions(
            path: 'https://ligg.test/',
            connectTimeout: const Duration(milliseconds: 100)),
        null,
        cancel.future);
    await expectLater(
        result,
        throwsA(isA<DioException>()
            .having((error) => error.type, 'type', DioExceptionType.cancel)));
  });
}

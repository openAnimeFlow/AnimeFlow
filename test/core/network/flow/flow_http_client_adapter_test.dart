import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/network/flow/flow_http_client_adapter.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late FlowEndpointPool pool;
  late FlowHttpClientAdapter adapter;

  RequestOptions options(String path, {String method = 'GET'}) =>
      RequestOptions(
          path: 'http://127.0.0.1:${server.port}$path',
          method: method,
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2));

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    pool = FlowEndpointPool();
    adapter = FlowHttpClientAdapter(pool: pool);
  });

  tearDown(() async {
    adapter.close(force: true);
    await server.close(force: true);
    pool.dispose();
  });

  test('route change preserves old SSE while new fetches use a new connection',
      () async {
    final connections = <int>{};
    late HttpResponse eventsResponse;
    server.listen((request) async {
      connections.add(request.connectionInfo!.remotePort);
      if (request.uri.path == '/events') {
        eventsResponse = request.response
          ..headers.contentType = ContentType('text', 'event-stream')
          ..bufferOutput = false;
        eventsResponse.write('data: first\n\n');
        await eventsResponse.flush();
      } else {
        request.response.write('new');
        await request.response.close();
      }
    });

    final response = await adapter.fetch(options('/events'), null, null);
    final first = Completer<void>();
    final second = Completer<void>();
    var received = '';
    final subscription = utf8.decoder.bind(response.stream).listen((chunk) {
      received += chunk;
      if (received.contains('first') && !first.isCompleted) first.complete();
      if (received.contains('second') && !second.isCompleted) second.complete();
    });
    addTearDown(subscription.cancel);
    await first.future.timeout(const Duration(seconds: 2));

    final beforeChange = await adapter.fetch(options('/before'), null, null);
    await beforeChange.stream.drain<void>();
    expect(connections, hasLength(2));
    pool.networkChanged();
    final newResponse = await adapter.fetch(options('/new'), null, null);
    expect(await utf8.decoder.bind(newResponse.stream).join(), 'new');
    expect(connections, hasLength(3));
    eventsResponse.write('data: second\n\n');
    await eventsResponse.flush();
    await second.future.timeout(const Duration(seconds: 2));
    final done = subscription.asFuture<void>();
    await eventsResponse.close();
    await done.timeout(const Duration(seconds: 2));
  });

  test('retiring a generation preserves a request waiting for headers',
      () async {
    final arrived = Completer<HttpRequest>();
    server.listen(arrived.complete);
    final pending = adapter.fetch(options('/'), null, null);
    final request = await arrived.future.timeout(const Duration(seconds: 2));
    pool.networkChanged();
    request.response.write('completed');
    await request.response.close();
    final response = await pending;
    expect(await utf8.decoder.bind(response.stream).join(), 'completed');
  });

  test('connection errors after receiving a POST do not replay its body',
      () async {
    var requests = 0;
    final bodies = <List<int>>[];
    server.listen((request) async {
      requests++;
      bodies.add(await request
          .fold<List<int>>([], (body, bytes) => body..addAll(bytes)));
      final socket = await request.response.detachSocket(writeHeaders: false);
      socket.destroy();
    });
    await expectLater(
        adapter.fetch(options('/write', method: 'POST'),
            Stream.value(Uint8List.fromList([1, 2, 3])), null),
        throwsA(isA<DioException>()));
    expect(requests, 1);
    expect(bodies, [
      [1, 2, 3]
    ]);
  });

  test('already cancelled token cancels acquisition before a request exists',
      () async {
    final cancel = Completer<void>()..complete();
    await expectLater(
        adapter.fetch(options('/'), null, cancel.future),
        throwsA(isA<DioException>()
            .having((error) => error.type, 'type', DioExceptionType.cancel)));
  });
}

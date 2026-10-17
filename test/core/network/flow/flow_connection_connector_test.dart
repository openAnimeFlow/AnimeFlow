import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/core/network/flow/flow_connection_connector.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tls_fixture.dart';

void main() {
  for (final wrongHost in [false, true]) {
    test('rejects ${wrongHost ? 'wrong hostname' : 'untrusted'} certificate',
        () async {
      final server = await testTlsServer();
      addTearDown(() => server.close(force: true));
      server.listen((request) => request.response.close(), onError: (_) {});
      final endpoint = Uri.parse(
          'https://${wrongHost ? 'wrong.test' : 'ligg.test'}:${server.port}');
      final connector = FlowConnectionConnector(
          endpoint: endpoint,
          addresses: ['127.0.0.1'],
          allowDnsFallback: false,
          securityContext: wrongHost ? trustedTestContext() : null);
      final task = await connector.connect(endpoint, null, null);
      await expectLater(task.socket, throwsA(isA<HandshakeException>()));
    });
  }

  test(
      'failed primary falls back before any HTTP request, DNS gets original hostname',
      () async {
    final server = await testTlsServer();
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      await request.response.close();
    });
    final failed = <String>[];
    final endpoint = Uri.parse('https://localhost:${server.port}');
    final connector = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: ['127.0.0.2', '127.0.0.3'],
        securityContext: trustedTestContext(),
        onAddressFailure: failed.add);
    final client = connector.createClient()..findProxy = (_) => 'DIRECT';
    addTearDown(() => client.close(force: true));
    final request = await client.postUrl(endpoint);
    request.write('one write');
    await (await request.close()).drain<void>();
    expect(failed, ['127.0.0.2', '127.0.0.3']);
    expect(requests, 1);
  });

  test('short connection budgets skip candidate attempts to reserve DNS time',
      () async {
    final server = await testTlsServer();
    addTearDown(() => server.close(force: true));
    server.listen((request) => request.response.close(), onError: (_) {});
    final endpoint = Uri.parse('https://localhost:${server.port}');
    final failed = <String>[];
    final connector = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: ['127.0.0.2'],
        securityContext: trustedTestContext(),
        onAddressFailure: failed.add);
    final context = FlowConnectionContext(budget: const Duration(seconds: 2));
    final task = await runZoned(() => connector.connect(endpoint, null, null),
        zoneValues: {FlowConnectionContext.zoneKey: context});
    final socket = await task.socket;
    socket.destroy();
    expect(failed, isEmpty);
  });

  test('cancellation during TLS closes the attempt and never dials a backup',
      () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = Completer<Socket>();
    server.listen((socket) {
      if (!accepted.isCompleted) accepted.complete(socket);
    });
    addTearDown(() => server.close());
    final endpoint = Uri.parse('https://ligg.test:${server.port}');
    final failures = <String>[];
    final connector = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: ['127.0.0.1', '127.0.0.2'],
        onAddressFailure: failures.add);
    final context = FlowConnectionContext();
    final task = await runZoned(() => connector.connect(endpoint, null, null),
        zoneValues: {FlowConnectionContext.zoneKey: context});
    final assertion =
        expectLater(task.socket, throwsA(isA<FlowConnectionCancelled>()));
    final peer = await accepted.future;
    addTearDown(peer.destroy);
    final peerClosed = peer.drain<void>();
    await Future<void>.delayed(Duration.zero);
    context.cancel();
    await assertion;
    await peerClosed.timeout(const Duration(seconds: 1));
    expect(failures, isEmpty);
  });

  test(
      'proxy factory returns plain TCP to proxy instead of dialing candidate IP',
      () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final peers = <Socket>[];
    server.listen(peers.add);
    addTearDown(() async {
      for (final p in peers) {
        p.destroy();
      }
      await server.close();
    });
    final connector = FlowConnectionConnector(
        endpoint: Uri.parse('https://ligg.test'), addresses: ['104.19.52.165']);
    final task = await connector.connect(
        Uri.parse('https://ligg.test'), '127.0.0.1', server.port);
    final socket = await task.socket;
    expect(socket, isNot(isA<SecureSocket>()));
    expect(socket.remoteAddress, InternetAddress.loopbackIPv4);
    expect(socket.remotePort, server.port);
    socket.destroy();
  });

  test('IP TLS preserves the HTTP host, large streams and connection reuse',
      () async {
    final server = await testTlsServer();
    addTearDown(() => server.close(force: true));
    final endpoint = Uri.parse('https://ligg.test:${server.port}');
    final received = <int>[];
    final connections = <int>{};
    server.listen((request) async {
      connections.add(request.connectionInfo!.remotePort);
      expect(request.headers.value('host'), 'ligg.test:${server.port}');
      received.add((await utf8.decoder.bind(request).join()).length);
      request.response.write('z' * 200000);
      await request.response.close();
    });
    final connector = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: ['127.0.0.1'],
        allowDnsFallback: false,
        securityContext: trustedTestContext());
    final client = connector.createClient()..findProxy = (_) => 'DIRECT';
    addTearDown(() => client.close(force: true));
    for (var index = 0; index < 2; index++) {
      final request = await client.postUrl(endpoint);
      await request.addStream(Stream.value(utf8.encode('a' * 200000)));
      final response = await request.close();
      expect(response.persistentConnection, isTrue);
      expect((await utf8.decoder.bind(response).join()).length, 200000);
      await Future<void>.delayed(Duration.zero);
    }
    expect(received, [200000, 200000]);
    expect(connections, hasLength(1));
  });

  test('redirect to a different HTTPS host validates its own TLS name',
      () async {
    final server = await testTlsServer();
    addTearDown(() => server.close(force: true));
    final endpoint = Uri.parse('https://ligg.test:${server.port}');
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.statusCode = 302;
      // 证书只包含域名，重定向后的 IP 地址必须独立校验证书。
      request.response.headers
          .set('location', 'https://127.0.0.1:${server.port}/final');
      await request.response.close();
    }, onError: (_) {});
    final client = FlowConnectionConnector(
            endpoint: endpoint,
            addresses: ['127.0.0.1'],
            securityContext: trustedTestContext())
        .createClient()
      ..findProxy = (_) => 'DIRECT';
    addTearDown(() => client.close(force: true));
    final request = await client.getUrl(endpoint);
    await expectLater(request.close(), throwsA(isA<HandshakeException>()));
    expect(requests, 1);
  });
}

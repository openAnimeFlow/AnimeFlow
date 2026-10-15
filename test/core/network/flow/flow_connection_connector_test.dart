import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/core/network/flow/flow_connection_connector.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tls_fixture.dart';

void main() {
  test(
      'IP TLS connection preserves the original HTTP host and validated domain',
      () async {
    final server = await testTlsServer();
    addTearDown(() => server.close(force: true));
    final endpoint = Uri.parse('https://ligg.test:${server.port}');
    server.listen((request) async {
      request.response.write(request.headers.value('host'));
      await request.response.close();
    });
    final client = FlowConnectionConnector(
            endpoint: endpoint,
            addresses: ['127.0.0.1'],
            allowDnsFallback: false,
            securityContext: trustedTestContext())
        .createClient()
      ..findProxy = (_) => 'DIRECT';
    addTearDown(() => client.close(force: true));
    final response = await (await client.getUrl(endpoint)).close();
    expect(
        await utf8.decoder.bind(response).join(), 'ligg.test:${server.port}');
  });

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
    final dialed = <String>[];
    final failed = <String>[];
    final endpoint = Uri.parse('https://ligg.test:${server.port}');
    final connector = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: ['104.19.52.165', '172.66.214.245'],
        securityContext: trustedTestContext(),
        onAddressFailure: failed.add,
        rawDial: (host, port) async {
          dialed.add(host);
          if (host != 'ligg.test') throw const SocketException('offline');
          return RawSocket.startConnect('127.0.0.1', port);
        });
    final client = connector.createClient()..findProxy = (_) => 'DIRECT';
    addTearDown(() => client.close(force: true));
    final request = await client.postUrl(endpoint);
    request.write('one write');
    await (await request.close()).drain<void>();
    expect(dialed, ['104.19.52.165', '172.66.214.245', 'ligg.test']);
    expect(failed, ['104.19.52.165', '172.66.214.245']);
    expect(requests, 1);
  });

  test('short connection budgets skip candidate attempts to reserve DNS time',
      () async {
    final server = await testTlsServer();
    addTearDown(() => server.close(force: true));
    server.listen((request) => request.response.close(), onError: (_) {});
    final endpoint = Uri.parse('https://ligg.test:${server.port}');
    final dialed = <String>[];
    final connector = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: ['104.19.52.165'],
        securityContext: trustedTestContext(),
        rawDial: (host, port) {
          dialed.add(host);
          return RawSocket.startConnect('127.0.0.1', port);
        });
    final context = FlowConnectionContext(budget: const Duration(seconds: 2));
    final task = await runZoned(() => connector.connect(endpoint, null, null),
        zoneValues: {FlowConnectionContext.zoneKey: context});
    final socket = await task.socket;
    socket.destroy();
    expect(dialed, ['ligg.test']);
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
    final dialed = <String>[];
    final failures = <String>[];
    final connector = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: ['127.0.0.1', '127.0.0.2'],
        onAddressFailure: failures.add,
        rawDial: (host, port) {
          dialed.add(host);
          return RawSocket.startConnect(host, port);
        });
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
    expect(dialed, ['127.0.0.1']);
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
    final hosts = <String>[];
    final connector = FlowConnectionConnector(
        endpoint: Uri.parse('https://ligg.test'),
        addresses: ['104.19.52.165'],
        dial: (host, port) {
          hosts.add(host);
          return Socket.startConnect(host, port);
        });
    final task = await connector.connect(
        Uri.parse('https://ligg.test'), '127.0.0.1', server.port);
    final socket = await task.socket;
    expect(socket, isNot(isA<SecureSocket>()));
    expect(hosts, ['127.0.0.1']);
    socket.destroy();
  });

  test('TLS socket handles large streams and reuses a keep-alive connection',
      () async {
    final server = await testTlsServer();
    addTearDown(() => server.close(force: true));
    final endpoint = Uri.parse('https://ligg.test:${server.port}');
    final received = <int>[];
    server.listen((request) async {
      received.add((await utf8.decoder.bind(request).join()).length);
      request.response.write('z' * 200000);
      await request.response.close();
    });
    var connections = 0;
    final connector = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: ['127.0.0.1'],
        allowDnsFallback: false,
        securityContext: trustedTestContext(),
        rawDial: (host, port) {
          connections++;
          return RawSocket.startConnect(host, port);
        });
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
    expect(connections, 1);
  });

  test(
      'redirect to a different HTTPS host resolves it and validates its own TLS name',
      () async {
    final server = await testTlsServer();
    addTearDown(() => server.close(force: true));
    final endpoint = Uri.parse('https://ligg.test:${server.port}');
    server.listen((request) async {
      if (request.uri.path == '/') {
        request.response.statusCode = 302;
        request.response.headers
            .set('location', 'https://localhost:${server.port}/final');
      } else {
        request.response.write('redirected');
      }
      await request.response.close();
    });
    final dialed = <String>[];
    final client = FlowConnectionConnector(
        endpoint: endpoint,
        addresses: ['127.0.0.1'],
        securityContext: trustedTestContext(),
        rawDial: (host, port) {
          dialed.add(host);
          return RawSocket.startConnect('127.0.0.1', port);
        }).createClient()
      ..findProxy = (_) => 'DIRECT';
    addTearDown(() => client.close(force: true));
    final response = await (await client.getUrl(endpoint)).close();
    expect(await utf8.decoder.bind(response).join(), 'redirected');
    expect(dialed, ['127.0.0.1', 'localhost']);
  });
}

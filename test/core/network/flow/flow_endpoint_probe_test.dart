import 'dart:async';
import 'dart:io';

import 'package:anime_flow/core/network/flow/flow_endpoint_probe.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tls_fixture.dart';

void main() {
  for (final scenario in [
    'valid',
    'tls12',
    'tls-off',
    '404',
    'challenge',
    'redirect',
    'wrong-host',
    'oversized'
  ]) {
    test('probe accepts only valid trace response: $scenario', () async {
      final server = await testTlsServer();
      addTearDown(() => server.close(force: true));
      final endpoint = Uri.parse('https://ligg.test:${server.port}');
      server.listen((request) async {
        expect(request.method, 'GET');
        expect(request.uri.path, '/cdn-cgi/trace');
        expect(request.headers.value('authorization'), isNull);
        expect(request.headers.value('cookie'), isNull);
        expect(request.headers.value('x-signature'), isNull);
        if (scenario == '404') request.response.statusCode = 404;
        if (scenario == 'redirect') {
          request.response.statusCode = 302;
          request.response.headers.set('location', 'https://other.test');
        }
        request.response.write(switch (scenario) {
          'challenge' => '<html>challenge</html>',
          'wrong-host' => 'h=other.test\ntls=TLSv1.3\n',
          'oversized' => 'h=ligg.test\ntls=TLSv1.3\nx=${'a' * 9000}',
          'tls12' => 'h=ligg.test\ntls=TLSv1.2\n',
          'tls-off' => 'h=ligg.test\ntls=off\n',
          _ => 'h=ligg.test\ntls=TLSv1.3\ncolo=TEST\n',
        });
        await request.response.close();
      });
      final probe = FlowEndpointProbe(
          endpoint: endpoint,
          securityContext: trustedTestContext(),
          findProxy: (_) => 'DIRECT');
      addTearDown(probe.cancel);
      final result = await probe.probe('127.0.0.1');
      expect(result != null, scenario == 'valid' || scenario == 'tls12');
    });
  }

  test('cancelling stalled header requests completes all probes', () async {
    final server = await testTlsServer();
    addTearDown(() => server.close(force: true));
    final endpoint = Uri.parse('https://ligg.test:${server.port}');
    final arrived = Completer<void>();
    var requests = 0;
    server.listen((request) {
      if (++requests == 2) arrived.complete();
      // Leave both responses pending so cancellation happens after TLS/HTTP.
    });
    final probe = FlowEndpointProbe(
        endpoint: endpoint,
        securityContext: trustedTestContext(),
        findProxy: (_) => 'DIRECT');
    addTearDown(probe.cancel);
    final pending = Future.wait([
      probe.probe('127.0.0.1'),
      probe.probe('127.0.0.1'),
    ]);
    await arrived.future.timeout(const Duration(seconds: 2));
    probe.cancel();
    expect(await pending.timeout(const Duration(seconds: 1)), [null, null]);
  });
}

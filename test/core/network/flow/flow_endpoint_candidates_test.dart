import 'package:anime_flow/core/network/flow/flow_endpoint_candidates.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registered Flutter asset contains valid IP candidates', () async {
    final text = await rootBundle.loadString(FlowEndpointPool.assetPath);
    final candidates = FlowEndpointCandidates.parse(text);

    expect(candidates.addresses, isNotEmpty);
    expect(candidates.rejectedLines, isEmpty);
  });

  test('normalizes BOM, whitespace, CRLF and duplicates without reordering',
      () {
    final candidates = FlowEndpointCandidates.parse(
      '\uFEFF 172.66.214.245 \r\n\r\n104.19.52.165\r\n172.66.214.245\n',
    );

    expect(candidates.addresses, ['172.66.214.245', '104.19.52.165']);
    expect(candidates.rejectedLines, isEmpty);
    expect(() => candidates.addresses.add('104.18.55.113'),
        throwsUnsupportedError);
  });

  test(
      'rejects malformed and non-Cloudflare addresses with source line numbers',
      () {
    final candidates = FlowEndpointCandidates.parse(
      '104.19.52.165\n\n127.0.0.1\ninvalid\n172.66.214.245\n',
    );
    expect(candidates.addresses, ['104.19.52.165', '172.66.214.245']);
    expect(candidates.rejectedLines, [3, 4]);
  });

  for (final address in [
    '127.0.0.1',
    '0.0.0.0',
    '10.0.0.1',
    '172.16.0.1',
    '192.168.1.1',
    '169.254.1.1',
    '100.64.0.1',
    '224.0.0.1',
    '255.255.255.255',
    '8.8.8.8',
    '1.1.1.1',
    '104.15.255.255',
    '104.28.0.0',
    '172.63.255.255',
    '172.72.0.0',
    '162.157.255.255',
    '162.160.0.0',
    '103.31.3.255',
    '103.31.8.0',
    '::1',
    '2606:4700::1111',
    '::ffff:104.19.52.165',
    '104.19.52.256',
    '0104.19.52.165',
    '104.19.52',
    '104.19.52.165/24',
    '104.19.52.165:443',
    '0x681334a5',
    '1746097317',
    'https://104.19.52.165',
    'ligg.top',
    '104.19.\uFEFF52.165',
  ]) {
    test('rejects unsupported address $address', () {
      expect(FlowEndpointCandidates.isAllowedAddress(address), isFalse);
    });
  }

  test('accepts boundaries of the ranges used in the bundled pool', () {
    for (final address in [
      '104.16.0.0',
      '104.23.255.255',
      '104.24.0.0',
      '104.27.255.255',
      '172.64.0.0',
      '172.71.255.255',
      '162.158.0.0',
      '162.159.255.255',
      '103.31.4.0',
      '103.31.7.255',
    ]) {
      expect(FlowEndpointCandidates.isAllowedAddress(address), isTrue,
          reason: address);
    }
  });

  test('hash depends on the normalized set, not ordering or formatting', () {
    final first = FlowEndpointCandidates.parse('172.66.214.245\n104.19.52.165');
    final reordered = FlowEndpointCandidates.parse(
      '\uFEFF104.19.52.165\r\n 172.66.214.245 \n104.19.52.165\n',
    );
    final changed = FlowEndpointCandidates.parse('172.66.214.245');

    expect(first.hash, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(first.hash, reordered.hash);
    expect(first.hash, isNot(changed.hash));
  });

  test('empty or entirely invalid input is a valid empty pool', () {
    for (final text in ['', '\uFEFF\r\n \n', 'localhost\n127.0.0.1']) {
      expect(FlowEndpointCandidates.parse(text).addresses, isEmpty);
    }
  });
}

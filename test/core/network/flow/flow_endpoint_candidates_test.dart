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

  test(
      'normalizes candidates and reports rejected source lines without reordering',
      () {
    final candidates = FlowEndpointCandidates.parse(
      '\uFEFF 104.19.52.165 \r\n\r\n127.0.0.1\ninvalid\n172.66.214.245\n104.19.52.165\n',
    );
    expect(candidates.addresses, ['104.19.52.165', '172.66.214.245']);
    expect(candidates.rejectedLines, [3, 4]);
  });

  test('rejects non-Cloudflare IPs and unsupported address formats', () {
    for (final address in [
      '127.0.0.1',
      '10.0.0.1',
      '224.0.0.1',
      '8.8.8.8',
      '104.15.255.255',
      '104.28.0.0',
      '::1',
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
      expect(FlowEndpointCandidates.isAllowedAddress(address), isFalse,
          reason: address);
    }
  });

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
}

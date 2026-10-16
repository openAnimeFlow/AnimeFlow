import 'package:anime_flow/core/network/flow/flow_endpoint_cache_repository.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';

import 'package:flutter_test/flutter_test.dart';

import 'flow_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const text = '172.66.214.245\n104.19.52.165';
  final now = DateTime.utc(2026, 10, 15, 12);
  final store = setUpFlowSettings();

  FlowEndpointPool pool(TextAssetBundle bundle) => FlowEndpointPool(
        assetBundle: bundle,
        cacheRepository: FlowEndpointCacheRepository(now: () => now),
      );

  test('duplicate initialization shares one asset/cache read', () async {
    final bundle = TextAssetBundle(text);
    final instance = pool(bundle);
    final first = instance.initialize();
    expect(identical(first, instance.initialize()), isTrue);
    await first;
    await instance.initialize();

    expect(bundle.reads, 1);
    expect(store.reads, 1);
    expect(instance.isAddressAvailable(ipA), isTrue);
    expect(instance.isAddressAvailable(ipB), isTrue);
    expect(instance.preferredAddresses, isEmpty);
  });

  test('cache failure preserves all loaded candidates', () async {
    store.failRead = true;
    final instance = pool(TextAssetBundle(text));
    await instance.initialize();
    expect(instance.isAddressAvailable(ipA), isTrue);
    expect(instance.isAddressAvailable(ipB), isTrue);
    expect(instance.preferredAddresses, isEmpty);
  });

  for (final text in <String?>[null, '', '127.0.0.1\ninvalid']) {
    test(
        'missing/empty/invalid asset safely keeps an empty candidate pool: $text',
        () async {
      final instance = pool(TextAssetBundle(text));
      await instance.probe();

      expect(instance.isAddressAvailable(ipA), isFalse);
      expect(instance.preferredAddresses, isEmpty);
      expect(store.reads, 0);
    });
  }
}

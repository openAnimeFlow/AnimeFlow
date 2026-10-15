import 'package:anime_flow/core/network/flow/flow_endpoint_cache.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_cache_repository.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_candidates.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';

import 'package:flutter_test/flutter_test.dart';

import 'flow_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const text = '172.66.214.245\n104.19.52.165';
  final now = DateTime.utc(2026, 10, 15, 12);
  final store = setUpFlowSettings();

  FlowEndpointPool pool(TextAssetBundle bundle, {List<String>? warnings}) =>
      FlowEndpointPool(
        assetBundle: bundle,
        cacheRepository:
            FlowEndpointCacheRepository(now: () => now, onWarning: (_) {}),
        onWarning: (message) => warnings?.add(message),
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
    expect(instance.candidates.addresses, ['172.66.214.245', '104.19.52.165']);
    expect(instance.cachedForRevalidation, isNull);
  });

  test('valid cache only changes revalidation order, not resource ordering',
      () async {
    store.value = FlowEndpointCache(
      host: 'ligg.top',
      port: 443,
      candidateHash: FlowEndpointCandidates.parse(text).hash,
      verifiedAt: now,
      measurements: const [
        FlowEndpointMeasurement(
            address: '104.19.52.165',
            latency: Duration(milliseconds: 80),
            successCount: 2),
      ],
    ).toMap();
    final instance = pool(TextAssetBundle(text));
    await instance.initialize();

    expect(instance.revalidationOrder, ['104.19.52.165', '172.66.214.245']);
    expect(instance.candidates.addresses, ['172.66.214.245', '104.19.52.165']);
    expect(store.writes, 0);
  });

  test('cache failure preserves all loaded candidates', () async {
    store.failRead = true;
    final instance = pool(TextAssetBundle(text));
    await instance.initialize();
    expect(instance.candidates.addresses, hasLength(2));
    expect(instance.cachedForRevalidation, isNull);
  });

  for (final text in <String?>[null, '', '127.0.0.1\ninvalid']) {
    test(
        'missing/empty/invalid asset safely keeps an empty candidate pool: $text',
        () async {
      final warnings = <String>[];
      final instance = pool(TextAssetBundle(text), warnings: warnings);
      await instance.initialize();

      expect(instance.candidates.addresses, isEmpty);
      expect(instance.revalidationOrder, isEmpty);
      expect(store.reads, 0);
      expect(warnings, isNotEmpty);
    });
  }
}

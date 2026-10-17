import 'dart:async';

import 'package:anime_flow/core/network/flow/flow_endpoint_cache.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_cache_repository.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_candidates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'flow_test_support.dart';

void main() {
  final endpoint = Uri.parse('https://ligg.top');
  final candidates = FlowEndpointCandidates.parse('172.66.214.245');
  final now = DateTime.utc(2026, 10, 15, 12);
  final store = setUpFlowSettings();
  late FlowEndpointCacheRepository repository;

  FlowEndpointCache cache({DateTime? verifiedAt}) => FlowEndpointCache(
        host: endpoint.host,
        port: endpoint.port,
        candidateHash: candidates.hash,
        verifiedAt: verifiedAt ?? now,
        measurements: const [
          FlowEndpointMeasurement(
              address: '172.66.214.245',
              latency: Duration(microseconds: 123456),
              successCount: 2),
        ],
      );

  Future<bool> save(FlowEndpointCache value) =>
      repository.save(value, endpoint: endpoint, candidates: candidates);
  Future<FlowEndpointCache?> load() =>
      repository.load(endpoint: endpoint, candidates: candidates);

  setUp(() {
    repository = FlowEndpointCacheRepository(now: () => now);
  });

  test('missing, corrupt and inaccessible cache are optional misses', () async {
    expect(await load(), isNull);
    store.value = {'version': 999};
    expect(await load(), isNull);
    store.failRead = true;
    expect(await load(), isNull);
    expect(store.writes, 0);
  });

  test('serializes simultaneous saves and rejects stale verification results',
      () async {
    store.writeGate = Completer<void>();
    final newer = save(cache());
    final older =
        save(cache(verifiedAt: now.subtract(const Duration(minutes: 1))));
    await Future<void>.delayed(Duration.zero);
    expect(store.writes, 1);
    store.writeGate!.complete();

    expect(await Future.wait([newer, older]), [true, false]);
    expect(store.maxActiveWrites, 1);
    expect((await load())!.verifiedAt, now);
  });

  test('failed writes do not poison the queue for later valid saves', () async {
    store.failWrite = true;
    expect(await save(cache()), isFalse);
    store.failWrite = false;
    expect(await save(cache()), isTrue);
    expect((await load())!.toMap(), cache().toMap());
  });

  test('queued snapshots from an invalidated network are not written',
      () async {
    store.writeGate = Completer<void>();
    final first = save(cache());
    var current = true;
    final stale = repository.save(cache(),
        endpoint: endpoint, candidates: candidates, isCurrent: () => current);
    await Future<void>.delayed(Duration.zero);
    current = false;
    store.writeGate!.complete();
    expect(await first, isTrue);
    expect(await stale, isFalse);
    expect(store.writes, 1);
  });
}

import 'dart:async';
import 'dart:io';

import 'package:anime_flow/core/network/flow/flow_endpoint_cache.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_cache_repository.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_candidates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

class MemoryCacheStore implements FlowEndpointCacheStore {
  Object? value;
  bool failRead = false;
  bool failWrite = false;
  int reads = 0;
  int writes = 0;
  int activeWrites = 0;
  int maxActiveWrites = 0;
  Completer<void>? writeGate;

  @override
  Future<Object?> read() async {
    reads++;
    if (failRead) throw StateError('storage unavailable');
    return value;
  }

  @override
  Future<void> write(Map<String, Object?> value) async {
    writes++;
    activeWrites++;
    if (activeWrites > maxActiveWrites) maxActiveWrites = activeWrites;
    try {
      if (failWrite) throw StateError('write unavailable');
      await writeGate?.future;
      this.value = value;
    } finally {
      activeWrites--;
    }
  }
}

void main() {
  final endpoint = Uri.parse('https://ligg.top');
  final candidates = FlowEndpointCandidates.parse('172.66.214.245');
  final now = DateTime.utc(2026, 10, 15, 12);
  late MemoryCacheStore store;
  late FlowEndpointCacheRepository repository;

  FlowEndpointCache cache({DateTime? verifiedAt}) => FlowEndpointCache(
        host: endpoint.host,
        port: endpoint.port,
        candidateHash: candidates.hash,
        verifiedAt: verifiedAt ?? now,
        measurements: const [
          FlowEndpointMeasurement(
              address: '172.66.214.245',
              latency: Duration(milliseconds: 50),
              successCount: 2),
        ],
      );

  Future<bool> save(FlowEndpointCache value) =>
      repository.save(value, endpoint: endpoint, candidates: candidates);
  Future<FlowEndpointCache?> load() =>
      repository.load(endpoint: endpoint, candidates: candidates);

  setUp(() {
    store = MemoryCacheStore();
    repository = FlowEndpointCacheRepository(
      store: store,
      now: () => now,
      onWarning: (_) {},
    );
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
    expect(await load(), isNotNull);
  });

  test('invalid or expired snapshots are not persisted', () async {
    expect(
        await save(cache(verifiedAt: now.subtract(const Duration(hours: 7)))),
        isFalse);
    expect(store.writes, 0);
  });

  test('persists and restores through a real Hive box without custom adapters',
      () async {
    final directory = await Directory.systemTemp.createTemp('flow_ip_cache_');
    Hive.init(directory.path);
    final box = await Hive.openBox<dynamic>('flow_ip_cache');
    addTearDown(() async {
      await box.close();
      // The deletion target is the specific temporary directory created above.
      expect(
          directory.absolute.path
              .startsWith(Directory.systemTemp.absolute.path),
          isTrue);
      await directory.delete(recursive: true);
    });
    final hiveRepository = FlowEndpointCacheRepository(
      store: HiveFlowEndpointCacheStore(box: () => box),
      now: () => now,
      onWarning: (_) {},
    );

    expect(
      await hiveRepository.save(cache(),
          endpoint: endpoint, candidates: candidates),
      isTrue,
    );
    final restored =
        await hiveRepository.load(endpoint: endpoint, candidates: candidates);
    expect(restored!.toMap(), cache().toMap());
  });
}

import 'dart:async';
import 'dart:math';

import 'package:anime_flow/core/network/flow/flow_endpoint_cache_repository.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_probe.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flow_endpoint_cache_repository_test.dart' show MemoryCacheStore;
import 'flow_endpoint_pool_test.dart' show TextAssetBundle;

const ipA = '104.19.52.165';
const ipB = '172.66.214.245';
const ipC = '162.159.82.236';

class FixedProbe implements FlowProbeSession {
  FixedProbe(this.values);
  final Map<String?, Duration?> values;
  int active = 0;
  int maxActive = 0;
  final calls = <String?>[];
  final pending = <Completer<Duration?>>[];
  bool hold = false;
  bool cancelled = false;

  @override
  Future<Duration?> probe(String? address) async {
    calls.add(address);
    active++;
    maxActive = max(maxActive, active);
    try {
      if (hold) {
        final completion = Completer<Duration?>();
        pending.add(completion);
        return await completion.future;
      }
      await Future<void>.delayed(Duration.zero);
      return cancelled ? null : values[address];
    } finally {
      active--;
    }
  }

  @override
  void cancel() {
    cancelled = true;
    for (final item in pending) {
      if (!item.isCompleted) item.complete(null);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryCacheStore store;
  late DateTime now;
  late Map<String?, Duration?> values;
  final sessions = <FixedProbe>[];

  FlowEndpointPool makePool(
      {Duration roundTimeout = const Duration(seconds: 15),
      bool holdFirst = false}) {
    final pool = FlowEndpointPool(
      assetBundle: TextAssetBundle('$ipA\n$ipB\n$ipC'),
      cacheRepository: FlowEndpointCacheRepository(
          store: store, now: () => now, onWarning: (_) {}),
      now: () => now,
      random: Random(1),
      roundTimeout: roundTimeout,
      probeFactory: (_) {
        final probe = FixedProbe(values)..hold = holdFirst && sessions.isEmpty;
        sessions.add(probe);
        return probe;
      },
      onWarning: (_) {},
    );
    addTearDown(pool.dispose);
    return pool;
  }

  setUp(() {
    store = MemoryCacheStore();
    now = DateTime.utc(2026, 10, 15, 12);
    sessions.clear();
    values = {
      null: const Duration(milliseconds: 600),
      ipA: const Duration(milliseconds: 50),
      ipB: const Duration(milliseconds: 100),
      ipC: const Duration(milliseconds: 150)
    };
  });

  test(
      'confirms two fresh samples, selects main/backups and limits concurrency',
      () async {
    final pool = makePool();
    final first = pool.probe();
    expect(identical(first, pool.probe()), isTrue);
    await first;
    expect(pool.preferredAddresses, [ipA, ipB, ipC]);
    expect(sessions.single.maxActive, lessThanOrEqualTo(3));
    expect(sessions.single.calls.where((ip) => ip == ipA), hasLength(2));
    expect(store.writes, 1);
  });

  test('keeps DNS if faster or improvement is below 100ms', () async {
    values[null] = const Duration(milliseconds: 30);
    final fastDns = makePool();
    await fastDns.probe();
    expect(fastDns.preferredAddresses, isEmpty);
    values[null] = const Duration(milliseconds: 120);
    final smallGain = makePool();
    await smallGain.probe();
    expect(smallGain.preferredAddresses, isEmpty);
  });

  test(
      'validated IP can be used if DNS is unavailable; total failure keeps DNS',
      () async {
    values[null] = null;
    final pool = makePool();
    await pool.probe();
    expect(pool.preferredAddresses.first, ipA);
    values = {null: null, ipA: null, ipB: null, ipC: null};
    await pool.probe();
    expect(pool.preferredAddresses, isEmpty);
  });

  test('connection failures cool down the actual IP; stale generations ignored',
      () async {
    final pool = makePool();
    await pool.probe();
    pool.reportConnectionFailure(ipA, pool.networkGeneration);
    expect(pool.preferredAddresses, [ipB, ipC]);
    expect(pool.isAddressAvailable(ipA), isFalse);
    now = now.add(const Duration(minutes: 1));
    expect(pool.isAddressAvailable(ipA), isTrue);
    final oldGeneration = pool.networkGeneration;
    pool.networkChanged();
    pool.reportConnectionFailure(ipB, oldGeneration);
    expect(pool.isAddressAvailable(ipB), isTrue);
    expect(pool.preferredAddresses, isEmpty);
  });

  test('network switch cancels old round and never publishes its results',
      () async {
    final pool = makePool(holdFirst: true);
    await pool.initialize();
    final pending = pool.probe();
    await Future<void>.delayed(Duration.zero);
    pool.networkChanged();
    await pending;
    expect(pool.preferredAddresses, isEmpty);
    expect(store.writes, 0);
    expect(sessions.single.cancelled, isTrue);
    await pool.probe();
    expect(pool.preferredAddresses.first, ipA);
  });

  test('expired live routes return to DNS pending revalidation', () async {
    final pool = makePool();
    await pool.probe();
    now = now.add(const Duration(hours: 6));
    pool.expireRoute();
    expect(pool.preferredAddresses, isEmpty);
  });

  test(
      'round deadline cancels stalled probes without counting them as failures',
      () async {
    final pool = makePool(
        holdFirst: true, roundTimeout: const Duration(milliseconds: 20));
    await pool.probe();
    expect(sessions.single.cancelled, isTrue);
    expect(sessions.single.active, 0);
    expect(pool.preferredAddresses, isEmpty);
    expect(pool.isAddressAvailable(ipA), isTrue);
    expect(store.writes, 0);
  });
}

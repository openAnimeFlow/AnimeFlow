import 'dart:async';
import 'dart:math';

import 'package:anime_flow/core/network/flow/flow_endpoint_cache.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_cache_repository.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_probe.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flow_test_support.dart';

class _CallbackProbe implements FlowProbeSession {
  _CallbackProbe(this.run);
  final Future<Duration?> Function(String?) run;

  @override
  Future<Duration?> probe(String? address) => run(address);

  @override
  void cancel() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = setUpFlowSettings();
  late DateTime now;
  late Map<String?, Duration?> values;
  final sessions = <FixedProbe>[];

  FlowEndpointPool makePool(
      {Duration roundTimeout = const Duration(seconds: 15),
      bool holdFirst = false,
      FlowProbeSession Function(Uri)? probeFactory}) {
    final pool = FlowEndpointPool(
      assetBundle: TextAssetBundle('$ipA\n$ipB\n$ipC'),
      cacheRepository:
          FlowEndpointCacheRepository(now: () => now, onWarning: (_) {}),
      now: () => now,
      random: Random(1),
      roundTimeout: roundTimeout,
      probeFactory: probeFactory ??
          (_) {
            final probe = FixedProbe(values)
              ..hold = holdFirst && sessions.isEmpty;
            sessions.add(probe);
            return probe;
          },
      onWarning: (_) {},
    );
    addTearDown(pool.dispose);
    return pool;
  }

  setUp(() {
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

  test('higher success rate bypasses latency hysteresis', () async {
    var dnsCalls = 0;
    final pool = makePool(
        probeFactory: (_) => _CallbackProbe((address) async {
              if (address == null) {
                return ++dnsCalls == 1
                    ? null
                    : const Duration(milliseconds: 50);
              }
              return const Duration(milliseconds: 100);
            }));
    await pool.probe();
    // DNS succeeds once out of two, each slower candidate succeeds twice.
    expect(pool.preferredAddresses, hasLength(3));
  });

  test('a later business failure wins over completed probe samples', () async {
    var round = 0;
    var dnsCalls = 0;
    var ipCalls = 0;
    final sampled = Completer<void>();
    final releaseDns = Completer<Duration?>();
    addTearDown(() {
      if (!releaseDns.isCompleted) releaseDns.complete(null);
    });
    final pool = makePool(probeFactory: (_) {
      if (++round != 2) return FixedProbe(values);
      return _CallbackProbe((address) async {
        if (address == null && ++dnsCalls == 2) return releaseDns.future;
        if (address == ipA && ++ipCalls == 2) sampled.complete();
        return values[address];
      });
    });
    await pool.probe();
    expect(pool.preferredAddresses, [ipA, ipB, ipC]);
    final pending = pool.probe();
    await sampled.future;
    await Future<void>.delayed(Duration.zero);
    pool.reportConnectionFailure(ipA, pool.networkGeneration);
    expect(pool.isAddressAvailable(ipA), isFalse);
    releaseDns.complete(values[null]);
    await pending;
    expect(pool.isAddressAvailable(ipA), isFalse);
    expect(pool.preferredAddresses, [ipB, ipC]);
    expect(
        FlowEndpointCache.fromMap(store.value)!
            .measurements
            .map((measurement) => measurement.address),
        isNot(contains(ipA)));

    // The address can recover with fresh samples after its cooldown expires.
    now = now.add(const Duration(minutes: 1));
    await pool.probe();
    expect(pool.isAddressAvailable(ipA), isTrue);
    expect(pool.preferredAddresses, contains(ipA));
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

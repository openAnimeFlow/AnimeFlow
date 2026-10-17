import 'dart:async';

import 'package:anime_flow/core/network/flow/flow_endpoint_cache.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_cache_repository.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_probe.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flow_test_support.dart';

class _CallbackProbe extends Fake implements FlowEndpointProbe {
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
      {String candidates = '$ipA\n$ipB\n$ipC',
      bool holdFirst = false,
      FlowEndpointProbe Function(Uri)? probeFactory}) {
    final pool = FlowEndpointPool(
      assetBundle: TextAssetBundle(candidates),
      cacheRepository: FlowEndpointCacheRepository(now: () => now),
      now: () => now,
      probeFactory: probeFactory ??
          (_) {
            final probe = FixedProbe(values)
              ..hold = holdFirst && sessions.isEmpty;
            sessions.add(probe);
            return probe;
          },
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
      'concurrent requests share one round and select main/backups with fresh samples',
      () async {
    final pool = makePool();
    await Future.wait([pool.probe(), pool.probe()]);
    expect(sessions, hasLength(1));
    expect(pool.preferredAddresses, [ipA, ipB, ipC]);
    expect(sessions.single.calls.where((ip) => ip == ipA), hasLength(2));
    expect(store.writes, 1);
    expect(pool.needsProbe, isFalse);
  });

  test('cold probes check at most three candidates and keep DNS usable',
      () async {
    final pool = makePool(candidates: '$ipA\n$ipB\n$ipC\n104.16.0.1');
    await pool.probe();
    final calls = sessions.single.calls;
    expect(calls.whereType<String>().toSet(), hasLength(3));
    expect({ipA, ipB, ipC, '104.16.0.1'},
        containsAll(calls.whereType<String>().toSet()));
    expect(calls.length, lessThanOrEqualTo(8));
    expect(sessions.single.maxActive, 1);
  });

  test(
      'cached primary needs four probes; failure expands within one small batch',
      () async {
    await makePool().probe();
    final pool = makePool();
    await pool.initialize();
    expect(pool.preferredAddresses, [ipA, ipB, ipC]);
    expect(pool.needsProbe, isTrue);
    await pool.probe();
    expect(sessions.last.calls, [null, ipA, ipA, null]);
    expect(pool.preferredAddresses, [ipA]);

    values[ipA] = null;
    pool.networkChanged();
    expect(pool.needsProbe, isTrue);
    await pool.probe();
    expect(sessions.last.calls.length, lessThanOrEqualTo(8));
    expect(pool.preferredAddresses, [ipB, ipC]);
    expect(FlowEndpointCache.fromMap(store.value)!.measurements.first.address,
        ipB);
  });

  test('keeps DNS if faster or improvement is below 100ms', () async {
    values[null] = const Duration(milliseconds: 30);
    final fastDns = makePool();
    await fastDns.probe();
    expect(fastDns.preferredAddresses, isEmpty);
    expect(fastDns.needsProbe, isFalse);
    fastDns.requestRevalidation();
    expect(fastDns.needsProbe, isTrue);
    values[null] = const Duration(milliseconds: 120);
    final smallGain = makePool();
    await smallGain.probe();
    expect(smallGain.preferredAddresses, isEmpty);
    final restarted = makePool();
    await restarted.initialize();
    expect(restarted.preferredAddresses, isEmpty);
  });

  test('restored routes retain their original expiry and reject expired caches',
      () async {
    await makePool().probe();
    now = now.add(const Duration(hours: 5));
    final restarted = makePool();
    await restarted.initialize();
    expect(restarted.preferredAddresses, [ipA, ipB, ipC]);
    restarted.reportConnectionFailure(ipA, restarted.networkGeneration);
    expect(restarted.preferredAddresses, [ipB, ipC]);
    expect(restarted.isAddressAvailable(ipA), isFalse);
    now = now.add(const Duration(hours: 1));
    restarted.expireRoute();
    expect(restarted.preferredAddresses, isEmpty);
    final expired = makePool();
    await expired.initialize();
    expect(expired.preferredAddresses, isEmpty);
  });

  test('network changes during initialization prevent restoring stale routes',
      () async {
    await makePool().probe();
    final restarted = makePool();
    final loading = restarted.initialize();
    restarted.networkChanged();
    await loading;
    expect(restarted.preferredAddresses, isEmpty);
    expect(restarted.needsProbe, isTrue);
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
    expect(pool.needsProbe, isTrue);

    values[null] = const Duration(milliseconds: 50);
    await pool.probe();
    expect(pool.preferredAddresses, isEmpty);
    expect(pool.needsProbe, isFalse);
    final restarted = makePool();
    await restarted.initialize();
    expect(restarted.preferredAddresses, isEmpty);
    await restarted.probe();
    expect(restarted.preferredAddresses, isEmpty);
  });

  test('connection failures cool down the actual IP; stale generations ignored',
      () async {
    final pool = makePool();
    await pool.probe();
    pool.reportConnectionFailure(ipA, pool.networkGeneration);
    expect(pool.needsProbe, isTrue);
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

  test('revalidation requests preserve the expiry of retained routes',
      () async {
    final pool = makePool();
    await pool.probe();
    expect(pool.needsProbe, isFalse);
    pool.requestRevalidation();
    expect(pool.needsProbe, isTrue);
    expect(pool.preferredAddresses.first, ipA);
    now = now.add(const Duration(hours: 6));
    pool.expireRoute();
    expect(pool.preferredAddresses, isEmpty);
    await pool.probe();
    expect(pool.needsProbe, isFalse);
    expect(pool.preferredAddresses.first, ipA);
  });

  test(
      'round deadline cancels stalled probes without counting them as failures',
      () {
    fakeAsync((clock) {
      final pool = makePool(holdFirst: true);
      var completed = false;
      unawaited(pool.probe().then((_) => completed = true));
      clock.elapse(const Duration(milliseconds: 14999));
      expect(completed, isFalse);
      clock.elapse(const Duration(milliseconds: 1));
      expect(completed, isTrue);
      expect(sessions.single.cancelled, isTrue);
      expect(sessions.single.active, 0);
      expect(pool.preferredAddresses, isEmpty);
      expect(pool.isAddressAvailable(ipA), isTrue);
      expect(store.writes, 0);
      pool.dispose();
    });
  });
}

import 'dart:async';

import 'package:anime_flow/core/network/flow/flow_endpoint_cache_repository.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:anime_flow/core/network/flow/flow_network_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flow_test_support.dart';

class _ServiceHarness {
  _ServiceHarness(Future<List<ConnectivityResult>> Function() read) {
    pool = FlowEndpointPool(
      assetBundle: TextAssetBundle(ipA),
      cacheRepository: FlowEndpointCacheRepository(onWarning: (_) {}),
      probeFactory: (_) {
        rounds++;
        return FixedProbe({
          null: const Duration(milliseconds: 500),
          ipA: const Duration(milliseconds: 50),
        });
      },
    );
    service = FlowNetworkService(
        pool: pool, networkChanges: events.stream, readConnectivity: read);
  }

  final events =
      StreamController<List<ConnectivityResult>>.broadcast(sync: true);
  late final FlowEndpointPool pool;
  late final FlowNetworkService service;
  int rounds = 0;

  Future<void> dispose() async {
    await service.stop();
    await events.close();
    pool.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpFlowSettings();

  test('Wi-Fi/mobile switches remeasure in both directions after debounce', () {
    fakeAsync((clock) {
      final harness = _ServiceHarness(() async => [ConnectivityResult.wifi]);
      unawaited(harness.service.start());
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 2));
      expect(harness.rounds, 1);
      for (final type in [ConnectivityResult.mobile, ConnectivityResult.wifi]) {
        harness.events.add([type]);
        expect(harness.pool.preferredAddresses, isEmpty);
        clock.elapse(const Duration(milliseconds: 1999));
        final before = harness.rounds;
        clock.elapse(const Duration(milliseconds: 1));
        expect(harness.rounds, before + 1);
      }
      unawaited(harness.dispose());
      clock.flushMicrotasks();
    });
  });

  test(
      'background switches wait for foreground and stale initial reads are ignored',
      () {
    fakeAsync((clock) {
      final initialRead = Completer<List<ConnectivityResult>>();
      var reads = 0;
      final harness = _ServiceHarness(() => ++reads == 1
          ? initialRead.future
          : Future.value([ConnectivityResult.wifi]));
      unawaited(harness.service.start());
      harness.events.add([ConnectivityResult.mobile]);
      final generation = harness.pool.networkGeneration;
      initialRead.complete([ConnectivityResult.none]);
      clock.flushMicrotasks();
      expect(harness.pool.networkGeneration, generation);
      harness.service.didChangeAppLifecycleState(AppLifecycleState.paused);
      harness.events.add([ConnectivityResult.wifi]);
      clock.elapse(const Duration(seconds: 10));
      expect(harness.rounds, 0);
      harness.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      clock.elapse(const Duration(seconds: 2));
      expect(harness.rounds, 1);
      unawaited(harness.dispose());
      clock.flushMicrotasks();
    });
  });

  test('resume refreshes a missed offline-to-online change after debounce', () {
    fakeAsync((clock) {
      var network = ConnectivityResult.none;
      var reads = 0;
      final harness = _ServiceHarness(() async {
        reads++;
        return [network];
      });
      unawaited(harness.service.start());
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 2));
      expect(harness.rounds, 0);
      harness.service.didChangeAppLifecycleState(AppLifecycleState.paused);
      network = ConnectivityResult.wifi;
      harness.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      clock.flushMicrotasks();
      expect(reads, 2);
      clock.elapse(const Duration(milliseconds: 1999));
      expect(harness.rounds, 0);
      clock.elapse(const Duration(milliseconds: 1));
      expect(harness.rounds, 1);
      expect(harness.pool.preferredAddresses, [ipA]);
      unawaited(harness.dispose());
      clock.flushMicrotasks();
    });
  });

  test('unchanged resume snapshot preserves routes and ordinary throttle', () {
    fakeAsync((clock) {
      final harness = _ServiceHarness(() async => [ConnectivityResult.wifi]);
      unawaited(harness.service.start());
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 2));
      final generation = harness.pool.networkGeneration;
      expect(harness.rounds, 1);
      harness.service.didChangeAppLifecycleState(AppLifecycleState.paused);
      harness.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      clock.elapse(const Duration(seconds: 2));
      expect(harness.pool.networkGeneration, generation);
      expect(harness.pool.preferredAddresses, [ipA]);
      expect(harness.rounds, 1);
      unawaited(harness.dispose());
      clock.flushMicrotasks();
    });
  });

  for (final supersededBy in ['event', 'resume', 'stop']) {
    test('late resume snapshot is ignored after newer $supersededBy', () {
      fakeAsync((clock) {
        var reads = 0;
        final staleRead = Completer<List<ConnectivityResult>>();
        final harness = _ServiceHarness(() => ++reads == 2
            ? staleRead.future
            : Future.value([ConnectivityResult.wifi]));
        unawaited(harness.service.start());
        clock.flushMicrotasks();
        clock.elapse(const Duration(seconds: 2));
        harness.service.didChangeAppLifecycleState(AppLifecycleState.paused);
        harness.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        if (supersededBy == 'event') {
          harness.events.add([ConnectivityResult.mobile]);
        } else if (supersededBy == 'resume') {
          harness.service.didChangeAppLifecycleState(AppLifecycleState.paused);
          harness.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        } else {
          unawaited(harness.service.stop());
        }
        clock.flushMicrotasks();
        final generation = harness.pool.networkGeneration;
        staleRead.complete([ConnectivityResult.none]);
        clock.flushMicrotasks();
        expect(harness.pool.networkGeneration, generation);
        clock.elapse(const Duration(seconds: 2));
        expect(harness.rounds, supersededBy == 'event' ? 2 : 1);
        unawaited(harness.dispose());
        clock.flushMicrotasks();
      });
    });
  }
}

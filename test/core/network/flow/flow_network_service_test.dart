import 'dart:async';

import 'package:anime_flow/core/network/flow/flow_endpoint_cache_repository.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:anime_flow/core/network/flow/flow_network_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flow_endpoint_cache_repository_test.dart' show MemoryCacheStore;
import 'flow_endpoint_pool_test.dart' show TextAssetBundle;
import 'flow_endpoint_selection_test.dart' show FixedProbe, ipA;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Wi-Fi/mobile switches remeasure in both directions after debounce', () {
    fakeAsync((clock) {
      final events =
          StreamController<List<ConnectivityResult>>.broadcast(sync: true);
      var rounds = 0;
      final pool = FlowEndpointPool(
          assetBundle: TextAssetBundle(ipA),
          cacheRepository: FlowEndpointCacheRepository(
              store: MemoryCacheStore(), onWarning: (_) {}),
          probeFactory: (_) {
            rounds++;
            return FixedProbe({
              null: const Duration(milliseconds: 500),
              ipA: const Duration(milliseconds: 50)
            });
          });
      final service = FlowNetworkService(
          pool: pool,
          networkChanges: events.stream,
          readConnectivity: () async => [ConnectivityResult.wifi]);
      unawaited(service.start());
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 2));
      expect(rounds, 1);
      for (final type in [ConnectivityResult.mobile, ConnectivityResult.wifi]) {
        events.add([type]);
        expect(pool.preferredAddresses, isEmpty);
        clock.elapse(const Duration(milliseconds: 1999));
        final before = rounds;
        clock.elapse(const Duration(milliseconds: 1));
        expect(rounds, before + 1);
      }
      unawaited(service.stop());
      clock.flushMicrotasks();
      unawaited(events.close());
      pool.dispose();
      clock.flushMicrotasks();
    });
  });

  test(
      'background switches wait for foreground and stale initial reads are ignored',
      () {
    fakeAsync((clock) {
      final events =
          StreamController<List<ConnectivityResult>>.broadcast(sync: true);
      final initialRead = Completer<List<ConnectivityResult>>();
      var rounds = 0;
      final pool = FlowEndpointPool(
          assetBundle: TextAssetBundle(ipA),
          cacheRepository: FlowEndpointCacheRepository(
              store: MemoryCacheStore(), onWarning: (_) {}),
          probeFactory: (_) {
            rounds++;
            return FixedProbe(
                {null: null, ipA: const Duration(milliseconds: 50)});
          });
      final service = FlowNetworkService(
          pool: pool,
          networkChanges: events.stream,
          readConnectivity: () => initialRead.future);
      unawaited(service.start());
      events.add([ConnectivityResult.mobile]);
      final generation = pool.networkGeneration;
      initialRead.complete([ConnectivityResult.none]);
      clock.flushMicrotasks();
      expect(pool.networkGeneration, generation);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      events.add([ConnectivityResult.wifi]);
      clock.elapse(const Duration(seconds: 10));
      expect(rounds, 0);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      clock.elapse(const Duration(seconds: 2));
      expect(rounds, 1);
      unawaited(service.stop());
      clock.flushMicrotasks();
      unawaited(events.close());
      pool.dispose();
      clock.flushMicrotasks();
    });
  });
}

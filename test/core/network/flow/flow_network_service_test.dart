import 'dart:async';

import 'package:anime_flow/core/network/flow/flow_endpoint_cache_repository.dart';
import 'package:anime_flow/core/network/flow/flow_endpoint_pool.dart';
import 'package:anime_flow/core/network/flow/flow_network_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flow_test_support.dart';

class _ServiceHarness {
  _ServiceHarness(
      FakeAsync clock, Future<List<ConnectivityResult>> Function() read,
      {bool platformEvents = false}) {
    DateTime now() => DateTime.utc(2026, 10, 15).add(clock.elapsed);
    pool = FlowEndpointPool(
      now: now,
      assetBundle: TextAssetBundle('$ipA\n$ipB'),
      cacheRepository: FlowEndpointCacheRepository(now: now, onWarning: (_) {}),
      probeFactory: (_) {
        rounds++;
        return FixedProbe({
          null: const Duration(milliseconds: 500),
          fastest: const Duration(milliseconds: 50),
        });
      },
    );
    service = FlowNetworkService(
        pool: pool,
        now: now,
        networkChanges: platformEvents ? null : events.stream,
        readConnectivity: read);
  }

  final events =
      StreamController<List<ConnectivityResult>>.broadcast(sync: true);
  late final FlowEndpointPool pool;
  late final FlowNetworkService service;
  int rounds = 0;
  String fastest = ipA;

  Future<void> dispose() async {
    await service.stop();
    await events.close();
    pool.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpFlowSettings();

  for (final type in [ConnectivityResult.wifi, ConnectivityResult.mobile]) {
    test('same-type $type platform events remeasure and replace the IP', () {
      fakeAsync((clock) {
        late MockStreamHandlerEventSink nativeEvents;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
          MockStreamHandler.inline(
              onListen: (_, events) => nativeEvents = events),
        );
        final harness =
            _ServiceHarness(clock, () async => [type], platformEvents: true);
        unawaited(harness.service.start());
        clock.flushMicrotasks();
        nativeEvents.success([type.name]);
        clock.elapse(const Duration(milliseconds: 9999));
        expect(harness.rounds, 0);
        clock.elapse(const Duration(milliseconds: 1));
        expect(harness.pool.preferredAddresses, [ipA]);
        expect(harness.rounds, 1);

        harness.fastest = ipB;
        for (var i = 0; i < 3; i++) {
          nativeEvents.success([type.name]);
          clock.elapse(const Duration(milliseconds: 500));
        }
        expect(harness.pool.preferredAddresses, isEmpty);
        clock.elapse(const Duration(milliseconds: 1499));
        expect(harness.rounds, 1);
        clock.elapse(const Duration(milliseconds: 1));
        expect(harness.rounds, 2);
        expect(harness.pool.preferredAddresses, [ipB]);
        unawaited(harness.dispose());
        clock.flushMicrotasks();
      });
    });
  }

  test('Wi-Fi/mobile switches remeasure in both directions after debounce', () {
    fakeAsync((clock) {
      final harness =
          _ServiceHarness(clock, () async => [ConnectivityResult.wifi]);
      unawaited(harness.service.start());
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 10));
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
      final harness = _ServiceHarness(
          clock,
          () => ++reads == 1
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
      final harness = _ServiceHarness(clock, () async {
        reads++;
        return [network];
      });
      unawaited(harness.service.start());
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 10));
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

  test('ordinary focus changes preserve routes and ordinary throttle', () {
    fakeAsync((clock) {
      final harness =
          _ServiceHarness(clock, () async => [ConnectivityResult.wifi]);
      unawaited(harness.service.start());
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 10));
      final generation = harness.pool.networkGeneration;
      expect(harness.rounds, 1);
      harness.service.didChangeAppLifecycleState(AppLifecycleState.inactive);
      harness.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      clock.elapse(const Duration(seconds: 2));
      expect(harness.pool.networkGeneration, generation);
      expect(harness.pool.preferredAddresses, [ipA]);
      expect(harness.rounds, 1);
      clock.elapse(const Duration(minutes: 10));
      expect(harness.rounds, 1);
      unawaited(harness.dispose());
      clock.flushMicrotasks();
    });
  });

  for (final state in [AppLifecycleState.paused, AppLifecycleState.hidden]) {
    test('resume from $state revalidates even without a type change event', () {
      fakeAsync((clock) {
        final harness =
            _ServiceHarness(clock, () async => [ConnectivityResult.wifi]);
        unawaited(harness.service.start());
        clock.flushMicrotasks();
        clock.elapse(const Duration(seconds: 10));
        expect(harness.pool.preferredAddresses, [ipA]);
        harness.service.didChangeAppLifecycleState(state);
        harness.fastest = ipB;
        clock.elapse(const Duration(seconds: 10));
        expect(harness.rounds, 1);
        harness.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        clock.flushMicrotasks();
        expect(harness.pool.preferredAddresses, isEmpty);
        clock.elapse(const Duration(seconds: 2));
        expect(harness.rounds, 2);
        expect(harness.pool.preferredAddresses, [ipB]);
        unawaited(harness.dispose());
        clock.flushMicrotasks();
      });
    });
  }

  for (final supersededBy in ['event', 'resume', 'stop']) {
    test('late resume snapshot is ignored after newer $supersededBy', () {
      fakeAsync((clock) {
        var reads = 0;
        final staleRead = Completer<List<ConnectivityResult>>();
        final harness = _ServiceHarness(
            clock,
            () => ++reads == 2
                ? staleRead.future
                : Future.value([ConnectivityResult.wifi]));
        unawaited(harness.service.start());
        clock.flushMicrotasks();
        clock.elapse(const Duration(seconds: 10));
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
        expect(harness.rounds, supersededBy == 'stop' ? 1 : 2);
        unawaited(harness.dispose());
        clock.flushMicrotasks();
      });
    });
  }
}

import 'dart:async';

import 'package:anime_flow/core/network/flow/flow_probe_scheduler.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trailing debounce resets and preserves forced network remeasurement',
      () {
    fakeAsync((clock) {
      var runs = 0;
      final scheduler = FlowProbeScheduler(
          run: () async {
            runs++;
          },
          cancel: () {});
      scheduler.networkChanged(online: true);
      clock.elapse(const Duration(seconds: 1));
      scheduler.request();
      clock.elapse(const Duration(seconds: 1));
      scheduler.request();
      clock.elapse(const Duration(milliseconds: 1999));
      expect(runs, 0);
      clock.elapse(const Duration(milliseconds: 1));
      clock.flushMicrotasks();
      expect(runs, 1);
      scheduler.dispose();
    });
  });

  test('ordinary concurrent triggers reuse a running round without queueing',
      () {
    fakeAsync((clock) {
      var runs = 0;
      final pending = Completer<void>();
      final scheduler = FlowProbeScheduler(
          run: () {
            runs++;
            return pending.future;
          },
          cancel: () {});
      scheduler.request();
      clock.elapse(const Duration(seconds: 2));
      scheduler.request();
      scheduler.request();
      clock.elapse(const Duration(seconds: 10));
      expect(runs, 1);
      pending.complete();
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 3));
      expect(runs, 1);
      scheduler.dispose();
    });
  });

  test('both network-switch directions bypass throttle but retain debounce',
      () {
    fakeAsync((clock) {
      var runs = 0;
      final start = DateTime.utc(2026);
      final scheduler = FlowProbeScheduler(
          run: () async {
            runs++;
          },
          cancel: () {},
          now: () => start.add(clock.elapsed));
      scheduler.request();
      clock.elapse(const Duration(seconds: 2));
      expect(runs, 1);
      for (var switchDirection = 0; switchDirection < 2; switchDirection++) {
        scheduler.networkChanged(online: true);
        clock.elapse(const Duration(milliseconds: 1999));
        expect(runs, switchDirection + 1);
        clock.elapse(const Duration(milliseconds: 1));
        clock.flushMicrotasks();
        expect(runs, switchDirection + 2);
      }
      scheduler.dispose();
    });
  });

  test('new network waits for old cancelled round to release its sockets', () {
    fakeAsync((clock) {
      var runs = 0;
      var cancels = 0;
      final old = Completer<void>();
      final scheduler = FlowProbeScheduler(run: () {
        runs++;
        return runs == 1 ? old.future : Future<void>.value();
      }, cancel: () {
        cancels++;
      });
      scheduler.request();
      clock.elapse(const Duration(seconds: 2));
      scheduler.networkChanged(online: true);
      clock.elapse(const Duration(seconds: 3));
      expect(runs, 1);
      expect(cancels, 1);
      old.complete();
      clock.flushMicrotasks();
      expect(runs, 2);
      scheduler.dispose();
    });
  });

  test('offline/background suppress timers and foreground preserves force flag',
      () {
    fakeAsync((clock) {
      var runs = 0;
      final scheduler = FlowProbeScheduler(
          run: () async {
            runs++;
          },
          cancel: () {});
      scheduler.request();
      clock.elapse(const Duration(seconds: 1));
      scheduler.setActive(false);
      scheduler.networkChanged(online: false);
      clock.elapse(const Duration(minutes: 1));
      scheduler.networkChanged(online: true);
      clock.elapse(const Duration(minutes: 1));
      expect(runs, 0);
      scheduler.setActive(true);
      clock.elapse(const Duration(seconds: 2));
      expect(runs, 1);
      scheduler.dispose();
    });
  });

  test('ordinary probes are throttled, and dispose prevents pending callbacks',
      () {
    fakeAsync((clock) {
      var runs = 0;
      final start = DateTime.utc(2026);
      final scheduler = FlowProbeScheduler(
          run: () async {
            runs++;
          },
          cancel: () {},
          now: () => start.add(clock.elapsed));
      scheduler.request();
      clock.elapse(const Duration(seconds: 2));
      scheduler.request();
      clock.elapse(const Duration(seconds: 3));
      expect(runs, 1);
      clock.elapse(const Duration(minutes: 5));
      scheduler.request();
      clock.elapse(const Duration(seconds: 2));
      expect(runs, 2);
      scheduler.networkChanged(online: true);
      scheduler.dispose();
      clock.elapse(const Duration(minutes: 5));
      expect(runs, 2);
    });
  });
}

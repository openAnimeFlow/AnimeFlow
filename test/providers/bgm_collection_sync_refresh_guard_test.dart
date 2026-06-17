import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// 与 [BgmCollectionSync.refreshStatus] 相同的并发保护语义。
class _RefreshGuard {
  bool _inFlight = false;

  int callCount = 0;
  int concurrentPeak = 0;
  int active = 0;

  Future<void> run(Future<void> Function() action) async {
    if (_inFlight) {
      return;
    }
    _inFlight = true;
    try {
      active++;
      concurrentPeak = active > concurrentPeak ? active : concurrentPeak;
      callCount++;
      await action();
    } finally {
      active--;
      _inFlight = false;
    }
  }
}

void main() {
  test('refresh guard ignores overlapping refresh calls', () async {
    final guard = _RefreshGuard();
    final completer = Completer<void>();

    final first = guard.run(() async {
      await completer.future;
    });
    final second = guard.run(() async {});

    await Future<void>.delayed(Duration.zero);
    expect(guard.callCount, 1);

    completer.complete();
    await first;
    await second;
    expect(guard.callCount, 1);
    expect(guard.concurrentPeak, 1);
  });
}

import 'dart:async';

import 'package:anime_flow/core/async/serial_operation_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending native work completes before the next operation starts',
      () async {
    final queue = SerialOperationQueue(ensureReady: () {});
    final started = Completer<void>();
    final gate = Completer<void>();
    final operations = <String>[];
    final opening = queue.run(() async {
      operations.add('open');
      started.complete();
      await gate.future;
      operations.add('opened');
    });
    await started.future;
    final playing = queue.run(() async => operations.add('play'));
    var drained = false;
    final draining = queue.drained.then((_) => drained = true);
    await Future<void>.delayed(Duration.zero);
    expect(operations, ['open']);
    expect(drained, isFalse);
    gate.complete();
    await Future.wait([opening, playing, draining]);
    expect(operations, ['open', 'opened', 'play']);
    expect(drained, isTrue);
  });

  test('a failed operation does not prevent later operations', () async {
    final queue = SerialOperationQueue(ensureReady: () {});
    final opening =
        queue.run<void>(() async => throw StateError('open failed'));
    final failure = expectLater(opening, throwsStateError);
    final recovery = queue.run(() async => 'recovered');
    await failure;
    expect(await recovery, 'recovered');
    await queue.drained;
  });

  test('disposal cancels queued commands while allowing active work to drain',
      () async {
    var disposed = false;
    final queue = SerialOperationQueue(ensureReady: () {
      if (disposed) throw StateError('disposed');
    });
    final started = Completer<void>();
    final gate = Completer<void>();
    final active = queue.run(() async {
      started.complete();
      await gate.future;
    });
    await started.future;
    var commandRan = false;
    final queued = queue.run(() async => commandRan = true);
    final cancellation = expectLater(queued, throwsStateError);
    disposed = true;
    var drained = false;
    final draining = queue.drained.then((_) => drained = true);
    await Future<void>.delayed(Duration.zero);
    expect(drained, isFalse);
    expect(commandRan, isFalse);
    gate.complete();
    await Future.wait([active, cancellation, draining]);
    expect(drained, isTrue);
    expect(commandRan, isFalse);
  });
}

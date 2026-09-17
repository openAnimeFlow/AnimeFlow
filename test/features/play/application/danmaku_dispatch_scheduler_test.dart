import 'package:anime_flow/features/play/application/danmaku_dispatch_scheduler.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dispatches evenly and cancels pending items after invalidation',
      (tester) async {
    final items = List.generate(
      2,
      (index) => Danmaku(
        message: '$index',
        time: 1,
        type: 1,
        color: Colors.white,
        source: '[BiliBili]',
      ),
    );
    var epoch = 0;
    var playing = true;
    final emitted = <String>[];
    final scheduler = DanmakuDispatchScheduler(
      readSnapshot: () => DanmakuDispatchSnapshot(
        position: const Duration(seconds: 1),
        playing: playing,
        danmakuOn: true,
        danmakus: {1: items},
        epoch: epoch,
      ),
      onDanmaku: (item) => emitted.add(item.message),
    );
    addTearDown(scheduler.stop);

    scheduler.tick();
    await tester.pump(const Duration(milliseconds: 1));
    expect(emitted, ['0']);
    scheduler.invalidate();
    await tester.pump(const Duration(milliseconds: 500));
    expect(emitted, ['0']);

    scheduler.tick();
    await tester.pump(const Duration(milliseconds: 1));
    expect(emitted, ['0', '0']);
    playing = false;
    await tester.pump(const Duration(milliseconds: 500));
    expect(emitted, ['0', '0']);

    playing = true;
    scheduler.tick();
    epoch++;
    await tester.pump(const Duration(milliseconds: 500));
    expect(emitted, ['0', '0']);
  });
}

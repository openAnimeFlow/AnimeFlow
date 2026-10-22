import 'dart:async';

import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/presentation/utils/playback_screen_awake.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';
import 'package:wakelock_plus/wakelock_plus.dart'
    show wakelockPlusPlatformInstance;

class _Wakelock extends WakelockPlusPlatformInterface {
  final calls = <bool>[];
  Completer<void>? firstEnable;
  final started = Completer<void>();
  bool current = false;

  @override
  Future<void> toggle({required bool enable}) async {
    calls.add(enable);
    if (enable && !started.isCompleted) {
      started.complete();
      await firstEnable?.future;
    }
    current = enable;
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late WakelockPlusPlatformInterface original;
  late _Wakelock platform;
  setUp(() {
    original = wakelockPlusPlatformInstance;
    platform = _Wakelock();
    wakelockPlusPlatformInstance = platform;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  tearDown(() => wakelockPlusPlatformInstance = original);

  test('delayed old-page cleanup preserves the new page demand', () async {
    platform.firstEnable = Completer<void>();
    final oldEvents = StreamController<PlayerEvent>.broadcast(sync: true);
    final nextEvents = StreamController<PlayerEvent>.broadcast(sync: true);
    final oldPage = PlaybackScreenAwake(oldEvents.stream);
    final nextPage = PlaybackScreenAwake(nextEvents.stream);
    oldEvents.add(const PlayerPlayingChanged(true));
    await platform.started.future;
    final disposing = oldPage.dispose();
    expect(oldPage.dispose(), same(disposing));
    nextEvents.add(const PlayerPlayingChanged(true));
    platform.firstEnable!.complete();
    await disposing;
    await Future<void>.delayed(Duration.zero);
    expect(platform.current, isTrue);
    expect(platform.calls, isNot(contains(false)));
    await nextPage.dispose();
    expect(platform.current, isFalse);
    expect(platform.calls.last, isFalse);
    await oldEvents.close();
    await nextEvents.close();
  });

  test(
      'owners share demand, pause in background and release on terminal events',
      () async {
    final a = StreamController<PlayerEvent>.broadcast(sync: true);
    final b = StreamController<PlayerEvent>.broadcast(sync: true);
    final first = PlaybackScreenAwake(a.stream);
    final second = PlaybackScreenAwake(b.stream);
    a.add(const PlayerPlayingChanged(true));
    b.add(const PlayerPlayingChanged(true));
    await Future<void>.delayed(Duration.zero);
    expect(platform.calls, [true]);
    a.add(const PlayerPlayingChanged(false));
    await first.dispose();
    expect(platform.current, isTrue);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    expect(platform.current, isFalse);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(platform.current, isTrue);
    b.add(const PlayerCompleted());
    await Future<void>.delayed(Duration.zero);
    expect(platform.current, isFalse);
    b.add(const PlayerPlayingChanged(true));
    await Future<void>.delayed(Duration.zero);
    expect(platform.current, isTrue);
    await b.close();
    await second.dispose();
    expect(platform.current, isFalse);
    await a.close();
  });
}

import 'dart:typed_data';
import 'package:anime_flow/features/play/domain/player/video_fit.dart';
import 'dart:async';

import 'package:anime_flow/features/play/application/playback_coordinator.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/player_snapshot.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'screenshot returns bytes while disposal drains active work and cancels queued commands',
      () async {
    final started = Completer<void>();
    final gate = Completer<void>();
    final bytes = Uint8List.fromList([1, 2, 3]);
    final factory = _FakeEngineFactory(configure: (engine) {
      engine.screenshotBytes = bytes;
      engine.beforeOperation = (operation) async {
        if (operation == 'screenshot') {
          started.complete();
          await gate.future;
        }
      };
    });
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    await coordinator.initialize();
    final screenshot = coordinator.screenshot();
    await started.future;
    final disposal = coordinator.dispose();
    expect(factory.created.single.disposeCount, 0);
    final cancelled = coordinator.screenshot();
    gate.complete();
    expect(await screenshot, same(bytes));
    expect(await cancelled, isNull);
    await disposal;
    expect(factory.created.single.disposeCount, 1);
  });

  test('concurrent initialization shares one engine and one operation',
      () async {
    final started = Completer<void>();
    final gate = Completer<void>();
    final factory = _FakeEngineFactory(configure: (engine) {
      engine.beforeOperation = (operation) async {
        if (operation == 'initialize') {
          started.complete();
          await gate.future;
        }
      };
    });
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    addTearDown(coordinator.dispose);
    final first = coordinator.initialize();
    await started.future;
    final second = coordinator.initialize();
    expect(second, same(first));
    expect(factory.created, hasLength(1));
    gate.complete();
    await Future.wait([first, second]);
    expect(factory.created.single._events.hasListener, isTrue);
  });

  test('disposal waits for initialization without subscribing afterwards',
      () async {
    final started = Completer<void>();
    final gate = Completer<void>();
    final factory = _FakeEngineFactory(configure: (engine) {
      engine.beforeOperation = (operation) async {
        if (operation == 'initialize') {
          started.complete();
          await gate.future;
        }
      };
    });
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    final initializing = coordinator.initialize();
    await started.future;
    final engine = factory.created.single;
    final eventsDone = coordinator.events.drain<void>();
    final disposing = coordinator.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(engine.disposeCount, 0);
    expect(engine._events.hasListener, isFalse);
    gate.complete();
    await Future.wait([initializing, disposing, eventsDone]);
    expect(engine.disposeCount, 1);
    expect(engine._events.hasListener, isFalse);
    await expectLater(coordinator.initialize(), throwsStateError);
    expect(factory.created, hasLength(1));
  });

  test('disposal releases a failed initialization and closes events', () async {
    final factory = _FakeEngineFactory(failKernel: PlayerKernel.mediaKit);
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    await expectLater(coordinator.initialize(), throwsStateError);
    expect(factory.created.single.disposeCount, 0);
    final eventsDone = coordinator.events.drain<void>();
    await coordinator.dispose();
    await eventsDone;
    expect(factory.created.single.disposeCount, 1);
  });

  test(
      'disposal before initialization closes events without creating an engine',
      () async {
    final factory = _FakeEngineFactory();
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    final eventsDone = coordinator.events.drain<void>();
    await coordinator.dispose();
    await eventsDone;
    await expectLater(coordinator.initialize(), throwsStateError);
    expect(factory.created, isEmpty);
  });

  test('old engine cleanup failure keeps the committed engine playable',
      () async {
    final factory = _FakeEngineFactory(configure: (engine) {
      engine.beforeOperation = (operation) async {
        if (engine.kernel == PlayerKernel.mediaKit && operation == 'dispose') {
          throw StateError('old engine disposal failed');
        }
      };
    });
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    addTearDown(coordinator.dispose);
    await coordinator.initialize();
    expect(
        await coordinator.switchKernel(PlayerKernel.fvp, _snapshot()), isTrue);
    expect(coordinator.kernel, PlayerKernel.fvp);
    expect(factory.created.first.playCount, 0);
    expect(factory.created.first.disposeCount, 1);
    expect(factory.created.last.disposeCount, 0);
    expect(factory.created.last.playCount, 1);
  });

  test('playback failure after committing reports an error without rollback',
      () async {
    var failPlay = true;
    final factory = _FakeEngineFactory(configure: (engine) {
      engine.beforeOperation = (operation) async {
        if (engine.kernel == PlayerKernel.fvp &&
            operation == 'play' &&
            failPlay) {
          failPlay = false;
          throw StateError('new engine playback failed');
        }
      };
    });
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    addTearDown(coordinator.dispose);
    await coordinator.initialize();
    final errors = <PlayerError>[];
    final subscription = coordinator.events.listen((event) {
      if (event is PlayerError) errors.add(event);
    });
    addTearDown(subscription.cancel);
    expect(
        await coordinator.switchKernel(PlayerKernel.fvp, _snapshot()), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.kernel, PlayerKernel.fvp);
    expect(factory.created.first.playCount, 0);
    expect(factory.created.first.disposeCount, 1);
    expect(factory.created.last.disposeCount, 0);
    expect(errors, hasLength(1));
    await coordinator.play();
    expect(factory.created.last.playCount, 2);
  });

  test('failed candidate cleanup does not prevent restoring the current engine',
      () async {
    final factory = _FakeEngineFactory(
      failKernel: PlayerKernel.fvp,
      configure: (engine) {
        engine.beforeOperation = (operation) async {
          if (engine.kernel == PlayerKernel.fvp && operation == 'dispose') {
            throw StateError('candidate disposal failed');
          }
        };
      },
    );
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    addTearDown(coordinator.dispose);
    await coordinator.initialize();
    expect(
        await coordinator.switchKernel(PlayerKernel.fvp, _snapshot()), isFalse);
    expect(coordinator.kernel, PlayerKernel.mediaKit);
    expect(factory.created.first.disposeCount, 0);
    expect(factory.created.first.playCount, 1);
    expect(factory.created.last.disposeCount, 1);
  });

  test('engine disposal failure still closes events', () async {
    final factory = _FakeEngineFactory(configure: (engine) {
      engine.beforeOperation = (operation) async {
        if (operation == 'dispose') throw StateError('native disposal failed');
      };
    });
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    await coordinator.initialize();
    final eventsDone = coordinator.events.drain<void>();
    await coordinator.dispose();
    await eventsDone;
    expect(factory.created.single.disposeCount, 1);
  });

  for (final fails in [false, true]) {
    test(
        'kernel switch forwards pause and resumed playback events (failure: $fails)',
        () async {
      final factory = _FakeEngineFactory(
        failKernel: fails ? PlayerKernel.fvp : null,
        configure: (engine) => engine.emitPlayingChanges = true,
      );
      final coordinator = PlaybackCoordinator(
        engineFactory: factory.create,
        adBlocker: false,
        hardwareDecoder: true,
      );
      addTearDown(coordinator.dispose);
      final playing = <bool>[];
      final subscription = coordinator.events.listen((event) {
        if (event is PlayerPlayingChanged) playing.add(event.playing);
      });
      addTearDown(subscription.cancel);
      await coordinator.initialize();
      await coordinator.play();
      await Future<void>.delayed(Duration.zero);
      expect(playing, [true]);
      expect(await coordinator.switchKernel(PlayerKernel.fvp, _snapshot()),
          !fails);
      await Future<void>.delayed(Duration.zero);
      expect(playing, [true, false, true]);
      await coordinator.stop();
      await Future<void>.delayed(Duration.zero);
      expect(playing.last, isFalse);
    });
  }

  for (final stage in ['initialize', 'open', 'dispose']) {
    test('disposal during switch $stage releases both engines without resuming',
        () async {
      final started = Completer<void>();
      final gate = Completer<void>();
      final factory = _FakeEngineFactory(configure: (engine) {
        engine.beforeOperation = (operation) async {
          final target =
              stage == 'dispose' ? PlayerKernel.mediaKit : PlayerKernel.fvp;
          if (engine.kernel == target && operation == stage) {
            started.complete();
            await gate.future;
          }
        };
      });
      final coordinator = PlaybackCoordinator(
        engineFactory: factory.create,
        adBlocker: false,
        hardwareDecoder: true,
      );
      await coordinator.initialize();
      final switching = coordinator.switchKernel(PlayerKernel.fvp, _snapshot());
      await started.future;
      final queuedPlay = coordinator.play();
      var disposed = false;
      final disposal = coordinator.dispose().then((_) => disposed = true);
      await Future<void>.delayed(Duration.zero);
      expect(disposed, isFalse);
      gate.complete();
      expect(await switching, isFalse);
      await disposal;
      await queuedPlay;
      await coordinator.dispose();
      for (final engine in factory.created) {
        expect(engine.disposeCount, 1);
        expect(engine.playCount, 0);
      }
    });
  }

  test('an episode opened during switching runs on the new engine', () async {
    final started = Completer<void>();
    final gate = Completer<void>();
    final factory = _FakeEngineFactory(configure: (engine) {
      engine.beforeOperation = (operation) async {
        if (engine.kernel == PlayerKernel.fvp &&
            operation == 'open' &&
            !started.isCompleted) {
          started.complete();
          await gate.future;
        }
      };
    });
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    addTearDown(coordinator.dispose);
    await coordinator.initialize();
    final switching = coordinator.switchKernel(PlayerKernel.fvp, _snapshot());
    await started.future;
    final source = PlaybackSource(uri: Uri.parse('https://example.com/next'));
    final opening = coordinator.open(source);
    final playing = coordinator.play();
    expect(factory.created.first.openedSource, isNull);
    gate.complete();
    expect(await switching, isTrue);
    await opening;
    await playing;
    expect(factory.created.last.openedSource, same(source));
    expect(factory.created.first.openedSource, isNull);
    expect(factory.created.first.playCount, 0);
  });

  test('switches kernel before a video source is available', () async {
    final factory = _FakeEngineFactory();
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    addTearDown(coordinator.dispose);
    await coordinator.initialize();
    final switched = await coordinator.switchKernel(
        PlayerKernel.fvp,
        const PlayerSnapshot(
            source: null,
            position: Duration.zero,
            volume: 65,
            rate: 1.25,
            wasPlaying: false,
            fit: VideoFit.contain));
    expect(switched, isTrue);
    expect(coordinator.kernel, PlayerKernel.fvp);
    expect(factory.created.first.pauseCount, 0);
    expect(factory.created.first.disposeCount, 1);
    expect(factory.created.last.openedPosition, isNull);
    expect(factory.created.last.playCount, 0);
    expect(factory.created.last.volume, 65);
    expect(factory.created.last.rate, 1.25);
  });

  test('switches kernel and restores the playback snapshot', () async {
    final factory = _FakeEngineFactory();
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    addTearDown(coordinator.dispose);

    await coordinator.initialize();
    final source = PlaybackSource(uri: Uri.parse('https://example.com/a'));
    final snapshot = PlayerSnapshot(
      source: source,
      position: const Duration(seconds: 42),
      volume: 65,
      rate: 1.25,
      wasPlaying: true,
      fit: VideoFit.contain,
    );

    final switched = await coordinator.switchKernel(PlayerKernel.fvp, snapshot);
    final oldEngine = factory.created.first;
    final newEngine = factory.created.last;

    expect(switched, isTrue);
    expect(coordinator.kernel, PlayerKernel.fvp);
    expect(oldEngine.pauseCount, 1);
    expect(oldEngine.disposeCount, 1);
    expect(newEngine.openedPosition, const Duration(seconds: 42));
    expect(newEngine.volume, 65);
    expect(newEngine.rate, 1.25);
    expect(newEngine.playCount, 1);
  });

  test('keeps the current engine and resumes it when switching fails',
      () async {
    final factory = _FakeEngineFactory(failKernel: PlayerKernel.fvp);
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    addTearDown(coordinator.dispose);

    await coordinator.initialize();
    final current = factory.created.single;
    final switched = await coordinator.switchKernel(
      PlayerKernel.fvp,
      PlayerSnapshot(
        source: PlaybackSource(uri: Uri.parse('https://example.com/a')),
        position: Duration.zero,
        volume: 100,
        rate: 1,
        wasPlaying: true,
        fit: VideoFit.contain,
      ),
    );

    expect(switched, isFalse);
    expect(coordinator.kernel, current.kernel);
    expect(current.playCount, 1);
    await coordinator.pause();
    expect(current.pauseCount, 2);
    expect(factory.created.last.disposeCount, 1);
  });

  test('forwards engine events through the coordinator', () async {
    final factory = _FakeEngineFactory();
    final coordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    addTearDown(coordinator.dispose);

    await coordinator.initialize();
    final eventFuture = coordinator.events.first;
    factory.created.first.emit(const PlayerCompleted());

    expect(await eventFuture, isA<PlayerCompleted>());
  });
}

PlayerSnapshot _snapshot() => PlayerSnapshot(
      source: PlaybackSource(uri: Uri.parse('https://example.com/current')),
      position: const Duration(seconds: 42),
      volume: 100,
      rate: 1,
      wasPlaying: true,
      fit: VideoFit.contain,
    );

class _FakeEngineFactory {
  _FakeEngineFactory({this.failKernel, this.configure});

  final PlayerKernel? failKernel;
  final void Function(_FakePlayerEngine)? configure;
  final created = <_FakePlayerEngine>[];

  PlayerEngine create(PlayerKernel kernel,
      {required bool adBlocker, required bool hardwareDecoder}) {
    final engine = _FakePlayerEngine(
      kernel,
      shouldFail: kernel == failKernel,
    );
    configure?.call(engine);
    created.add(engine);
    return engine;
  }
}

class _FakePlayerEngine implements PlayerEngine {
  _FakePlayerEngine(this.kernel, {required this.shouldFail});

  @override
  final PlayerKernel kernel;
  final bool shouldFail;
  final _events = StreamController<PlayerEvent>.broadcast();
  int pauseCount = 0;
  int playCount = 0;
  int disposeCount = 0;
  bool emitPlayingChanges = false;
  Duration? openedPosition;
  PlaybackSource? openedSource;
  Future<void> Function(String operation)? beforeOperation;
  double? volume;
  double? rate;
  Uint8List? screenshotBytes;

  @override
  final capabilities = const PlayerCapabilities();

  @override
  Stream<PlayerEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {
    await beforeOperation?.call('initialize');
    if (shouldFail) throw StateError('initialize failed');
  }

  @override
  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  }) async {
    await beforeOperation?.call('open');
    if (shouldFail) throw StateError('open failed');
    openedSource = source;
    openedPosition = startPosition;
  }

  @override
  Future<void> play() async {
    playCount++;
    await beforeOperation?.call('play');
    if (emitPlayingChanges) emit(const PlayerPlayingChanged(true));
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    if (emitPlayingChanges) emit(const PlayerPlayingChanged(false));
  }

  @override
  Future<void> stop() async {
    if (emitPlayingChanges) emit(const PlayerPlayingChanged(false));
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Future<void> setRate(double rate) async => this.rate = rate;

  @override
  Future<Uint8List?> screenshot() async {
    await beforeOperation?.call('screenshot');
    return screenshotBytes;
  }

  @override
  Future<void> setShaders(String shaderList) async {}

  @override
  Future<double?> readCacheSpeed() async => null;

  @override
  Future<void> dispose() async {
    disposeCount++;
    try {
      await beforeOperation?.call('dispose');
    } finally {
      await _events.close();
    }
  }

  void emit(PlayerEvent event) => _events.add(event);
}

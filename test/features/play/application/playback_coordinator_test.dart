import 'dart:async';
import 'dart:typed_data';

import 'package:anime_flow/features/play/application/playback_coordinator.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/player_snapshot.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('switches kernel before a video source is available', () async {
    final factory = _FakeEngineFactory();
    final coordinator =
        PlaybackCoordinator(engineFactory: factory, adBlocker: false);
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
            fit: BoxFit.contain));
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
      engineFactory: factory,
      adBlocker: false,
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
      fit: BoxFit.contain,
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
      engineFactory: factory,
      adBlocker: false,
    );
    addTearDown(coordinator.dispose);

    await coordinator.initialize();
    final current = coordinator.engine;
    final switched = await coordinator.switchKernel(
      PlayerKernel.fvp,
      PlayerSnapshot(
        source: PlaybackSource(uri: Uri.parse('https://example.com/a')),
        position: Duration.zero,
        volume: 100,
        rate: 1,
        wasPlaying: true,
        fit: BoxFit.contain,
      ),
    );

    expect(switched, isFalse);
    expect(coordinator.engine, same(current));
    expect((current as _FakePlayerEngine).playCount, 1);
    expect(factory.created.last.disposeCount, 1);
  });

  test('forwards engine events through the coordinator', () async {
    final factory = _FakeEngineFactory();
    final coordinator = PlaybackCoordinator(
      engineFactory: factory,
      adBlocker: false,
    );
    addTearDown(coordinator.dispose);

    await coordinator.initialize();
    final eventFuture = coordinator.events.first;
    factory.created.first.emit(const PlayerCompleted());

    expect(await eventFuture, isA<PlayerCompleted>());
  });
}

class _FakeEngineFactory extends PlayerEngineFactory {
  _FakeEngineFactory({this.failKernel});

  final PlayerKernel? failKernel;
  final created = <_FakePlayerEngine>[];

  @override
  PlayerEngine create(PlayerKernel kernel, {required bool adBlocker}) {
    final engine = _FakePlayerEngine(
      kernel,
      shouldFail: kernel == failKernel,
    );
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
  Duration? openedPosition;
  double? volume;
  double? rate;

  @override
  final capabilities = const PlayerCapabilities();

  @override
  Stream<PlayerEvent> get events => _events.stream;

  @override
  Widget buildVideoSurface({required BoxFit fit}) => const SizedBox();

  @override
  Future<void> initialize() async {
    if (shouldFail) throw StateError('initialize failed');
  }

  @override
  Future<void> open(
    PlaybackSource source, {
    Duration? startPosition,
    bool autoPlay = false,
  }) async {
    if (shouldFail) throw StateError('open failed');
    openedPosition = startPosition;
  }

  @override
  Future<void> play() async => playCount++;

  @override
  Future<void> pause() async => pauseCount++;

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Future<void> setRate(double rate) async => this.rate = rate;

  @override
  Future<Uint8List?> screenshot() async => null;

  @override
  Future<void> setShaders(String shaderList) async {}

  @override
  Future<void> dispose() async {
    disposeCount++;
    await _events.close();
  }

  void emit(PlayerEvent event) => _events.add(event);
}

import 'dart:async';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/infrastructure/player/media_kit/media_kit_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() {
  test('each episode gets a new player and controller with saved settings',
      () async {
    final players = <_Player>[];
    final controllers = <Player>[];
    final engine = MediaKitEngine(
      adBlocker: false,
      playerFactory: () {
        final player = _Player();
        players.add(player);
        return player;
      },
      controllerFactory: (player) {
        controllers.add(player);
        return _Controller();
      },
    );
    addTearDown(engine.dispose);
    await engine.initialize();
    await engine.setVolume(35);
    await engine.setRate(1.5);
    for (var i = 0; i < 10; i++) {
      await engine.open(
        PlaybackSource(uri: Uri.parse('https://example.com/$i')),
        startPosition: Duration(seconds: i),
        autoPlay: true,
      );
      expect(players.length, i + 1);
      expect(controllers.last, same(players.last));
      expect(players.last.media!.start, Duration(seconds: i));
      expect(players.last.volume, 35);
      expect(players.last.rate, 1.5);
      expect(players.last.playing, isTrue);
      expect(players.take(i).every((p) => p.disposed), isTrue);
    }
  });

  test('overlapping opens wait for the previous open and release', () async {
    final first = _Player()..gate = Completer<void>();
    final second = _Player();
    var created = 0;
    final engine = MediaKitEngine(
      adBlocker: false,
      playerFactory: () => created++ == 0 ? first : second,
      controllerFactory: (_) => _Controller(),
    );
    addTearDown(engine.dispose);
    final source = PlaybackSource(uri: Uri.parse('https://example.com/video'));
    final opening = engine.open(source);
    await first.started.future;
    final next = engine.open(source);
    await Future<void>.delayed(Duration.zero);
    expect(created, 1);
    expect(first.disposed, isFalse);
    first.gate!.complete();
    await Future.wait([opening, next]);
    expect(first.disposed, isTrue);
    expect(second.media, isNotNull);
  });

  test('dispose waits for opening and prevents queued replacement', () async {
    final player = _Player()..gate = Completer<void>();
    var created = 0;
    final engine = MediaKitEngine(
      adBlocker: false,
      playerFactory: () {
        created++;
        return player;
      },
      controllerFactory: (_) => _Controller(),
    );
    final source = PlaybackSource(uri: Uri.parse('https://example.com/video'));
    final first = engine.open(source);
    final firstError = expectLater(first, throwsStateError);
    await player.started.future;
    final secondError = expectLater(engine.open(source), throwsStateError);
    final disposing = engine.dispose();
    expect(player.disposed, isFalse);
    player.gate!.complete();
    await Future.wait([firstError, secondError, disposing]);
    expect(created, 1);
    expect(player.disposed, isTrue);
  });
}

class _Controller implements VideoController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Player implements Player {
  bool disposed = false;
  bool playing = false;
  double volume = 100;
  double rate = 1;
  Media? media;
  Completer<void>? gate;
  final started = Completer<void>();
  @override
  PlayerStream get stream => _Streams();
  @override
  Future<void> open(Playable playable, {bool play = true}) async {
    media = playable as Media;
    started.complete();
    await gate?.future;
    playing = play;
  }

  @override
  Future<void> play() async {
    playing = true;
  }

  @override
  Future<void> setVolume(double value) async {
    volume = value;
  }

  @override
  Future<void> setRate(double value) async {
    rate = value;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Streams implements PlayerStream {
  @override
  Stream<bool> get playing => const Stream.empty();
  @override
  Stream<bool> get completed => const Stream.empty();
  @override
  Stream<bool> get buffering => const Stream.empty();
  @override
  Stream<Duration> get position => const Stream.empty();
  @override
  Stream<Duration> get duration => const Stream.empty();
  @override
  Stream<Duration> get buffer => const Stream.empty();
  @override
  Stream<double> get volume => const Stream.empty();
  @override
  Stream<double> get rate => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

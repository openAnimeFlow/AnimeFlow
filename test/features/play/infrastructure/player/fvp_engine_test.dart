import 'dart:async';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/infrastructure/player/fvp/fvp_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:fvp/mdk.dart' as fvp;

void main() {
  test('software decoding excludes native hardware decoders on every player',
      () async {
    final players = <_FakePlayer>[];
    final engine = FvpEngine(
        hardwareDecoder: false,
        playerFactory: () {
          final player = _FakePlayer();
          players.add(player);
          return player;
        });
    await engine.initialize();
    addTearDown(engine.dispose);
    final source = PlaybackSource(uri: Uri.parse('https://example.com/video'));
    await engine.open(source);
    await engine.open(source);
    expect(players, hasLength(2));
    for (final player in players) {
      expect(player.videoDecoders, ['FFmpeg', 'dav1d']);
    }
  });
  testWidgets('mounted video surface follows the replacement player',
      (tester) async {
    final players = <_FakePlayer>[];
    final engine = FvpEngine(playerFactory: () {
      final player = _FakePlayer()..textureCount = players.length * 100;
      players.add(player);
      return player;
    });
    await engine.initialize();
    await engine.setVolume(35);
    await engine.setRate(1.5);
    await tester.pumpWidget(engine.buildVideoSurface(fit: BoxFit.contain));
    final source = PlaybackSource(uri: Uri.parse('https://example.com/video'));
    await tester.runAsync(() => engine.open(source));
    await tester.pump();
    expect(tester.widget<Texture>(find.byType(Texture)).textureId, 1);
    await tester.runAsync(() => engine.open(source));
    await tester.pump();
    expect(tester.widget<Texture>(find.byType(Texture)).textureId, 101);
    expect(players.first.disposed, isTrue);
    expect(players.last.volume, 0.35);
    expect(players.last.playbackRate, 1.5);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(engine.dispose);
  });

  test('repeated loads create fresh players with initial positions', () async {
    final players = <_FakePlayer>[];
    final engine = FvpEngine(playerFactory: () {
      final player = _FakePlayer();
      players.add(player);
      return player;
    });
    await engine.initialize();
    addTearDown(engine.dispose);
    for (var episode = 0; episode < 10; episode++) {
      await engine.open(
        PlaybackSource(uri: Uri.parse('https://example.com/$episode')),
        autoPlay: true,
        startPosition: Duration(milliseconds: episode * 1000 + 375),
      );
      expect(players.length, episode + 1);
      expect(players.last.textureId.value, 1);
      expect(players.last.initialPosition, episode * 1000 + 375);
      expect(players.last.initialFlags.rawValue, fvp.SeekFlag.fromStart);
      expect(players.last.rendererOperations, ['prepare', 'create']);
      expect(players.take(episode).every((player) => player.disposed), isTrue);
    }
  });

  test('overlapping loads wait for pending texture creation', () async {
    final player = _FakePlayer()..textureGate = Completer<void>();
    final nextPlayer = _FakePlayer();
    var created = 0;
    final engine =
        FvpEngine(playerFactory: () => created++ == 0 ? player : nextPlayer);
    await engine.initialize();
    addTearDown(engine.dispose);
    final first = engine.open(
      PlaybackSource(uri: Uri.parse('https://example.com/1')),
    );
    await player.textureStarted.future;
    final second = engine.open(
      PlaybackSource(uri: Uri.parse('https://example.com/2')),
    );
    await Future<void>.delayed(Duration.zero);
    expect(player.prepares, 1);
    expect(player.rendererOperations, ['prepare', 'create']);
    player.textureGate!.complete();
    await Future.wait([first, second]);
    expect(player.disposed, isTrue);
    expect(nextPlayer.rendererOperations, ['prepare', 'create']);
    expect(nextPlayer.textureId.value, 1);
  });

  test('dispose waits for pending texture work and stops further loading',
      () async {
    final player = _FakePlayer()..textureGate = Completer<void>();
    final engine = FvpEngine(playerFactory: () => player);
    await engine.initialize();
    final opening = engine.open(
      PlaybackSource(uri: Uri.parse('https://example.com/1')),
    );
    final failed = expectLater(opening, throwsStateError);
    await player.textureStarted.future;
    final disposing = engine.dispose();
    expect(player.disposed, isFalse);
    player.textureGate!.complete();
    await failed;
    await disposing;
    expect(player.disposed, isTrue);
  });

  test('waits for native stop before preparing the next episode', () async {
    final player = _FakePlayer()
      ..nativeState = fvp.PlaybackState.playing
      ..delayStop = true;
    final engine = FvpEngine(playerFactory: () => player);
    await engine.initialize();
    addTearDown(engine.dispose);

    var opened = false;
    final opening = engine
        .open(PlaybackSource(uri: Uri.parse('https://example.com/episode2')))
        .then((_) => opened = true);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(opened, isFalse);
    expect(player.prepares, 0);

    player.nativeState = fvp.PlaybackState.stopped;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await opening;
    expect(player.prepares, 1);
    expect(opened, isTrue);
    await engine.dispose();
  });

  test('late callbacks use current native state for playback controls',
      () async {
    final player = _FakePlayer();
    final engine = FvpEngine(playerFactory: () => player);
    await engine.initialize();
    addTearDown(engine.dispose);
    final states = <bool>[];
    final subscription = engine.events.listen((event) {
      if (event is PlayerPlayingChanged) states.add(event.playing);
    });
    addTearDown(subscription.cancel);

    player.nativeState = fvp.PlaybackState.playing;
    player.changes.add((
      oldValue: fvp.PlaybackState.playing,
      newValue: fvp.PlaybackState.stopped,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(states.last, isTrue);

    await engine.pause();
    player.nativeState = fvp.PlaybackState.paused;
    player.changes.add((
      oldValue: fvp.PlaybackState.stopped,
      newValue: fvp.PlaybackState.playing,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(states.last, isFalse);
    await engine.dispose();
  });

  test('polling restores playing and paused states without callbacks',
      () async {
    final player = _FakePlayer();
    final engine = FvpEngine(playerFactory: () => player);
    await engine.initialize();
    addTearDown(engine.dispose);
    final states = <bool>[];
    final subscription = engine.events.listen((event) {
      if (event is PlayerPlayingChanged) states.add(event.playing);
    });
    addTearDown(subscription.cancel);
    await engine.open(
      PlaybackSource(uri: Uri.parse('https://example.com/episode2')),
    );

    await engine.play();
    final playing = engine.events.firstWhere(
      (event) => event is PlayerPlayingChanged && event.playing,
    );
    player.nativeState = fvp.PlaybackState.playing;
    await playing.timeout(const Duration(seconds: 2));
    expect(states.last, isTrue);
    await engine.pause();
    final paused = engine.events.firstWhere(
      (event) => event is PlayerPlayingChanged && !event.playing,
    );
    player.nativeState = fvp.PlaybackState.paused;
    await paused.timeout(const Duration(seconds: 2));
    expect(states.last, isFalse);
    await engine.dispose();
  });
  test('stop clears old metrics and ignores late buffering callbacks',
      () async {
    final player = _FakePlayer()..currentPosition = 42000;
    final engine = FvpEngine(playerFactory: () => player);
    await engine.initialize();
    addTearDown(engine.dispose);
    final events = <PlayerEvent>[];
    final subscription = engine.events.listen(events.add);
    addTearDown(subscription.cancel);
    await engine.open(
      PlaybackSource(uri: Uri.parse('https://example.com/episode1')),
    );
    player.mediaStatus = const fvp.MediaStatus(fvp.MediaStatus.buffering);
    player.emitMediaStatus(player.mediaStatus);
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<PlayerBufferingChanged>().last.buffering, isTrue);

    await engine.stop();
    player.emitMediaStatus(const fvp.MediaStatus(fvp.MediaStatus.buffering));
    await Future<void>.delayed(Duration.zero);
    expect(
        events.whereType<PlayerPositionChanged>().last.position, Duration.zero);
    expect(
        events.whereType<PlayerBufferedChanged>().last.buffered, Duration.zero);
    expect(
        events.whereType<PlayerDurationChanged>().last.duration, Duration.zero);
    expect(events.whereType<PlayerBufferingChanged>().last.buffering, isFalse);
  });

  test('next episode ignores old buffering status and polling clears buffering',
      () async {
    late _FakePlayer player;
    final engine = FvpEngine(playerFactory: () => player = _FakePlayer());
    await engine.initialize();
    addTearDown(engine.dispose);
    final buffering = <bool>[];
    final subscription = engine.events.listen((event) {
      if (event is PlayerBufferingChanged) buffering.add(event.buffering);
    });
    addTearDown(subscription.cancel);
    final source =
        PlaybackSource(uri: Uri.parse('https://example.com/episode1'));
    await engine.open(source);
    await engine.open(
      PlaybackSource(uri: Uri.parse('https://example.com/episode2')),
    );
    player.emitMediaStatus(const fvp.MediaStatus(fvp.MediaStatus.buffering));
    await Future<void>.delayed(Duration.zero);
    expect(buffering.last, isFalse);

    player.mediaStatus = const fvp.MediaStatus(fvp.MediaStatus.buffering);
    player.emitMediaStatus(player.mediaStatus);
    await Future<void>.delayed(Duration.zero);
    expect(buffering.last, isTrue);
    final recovered = engine.events.firstWhere(
      (event) => event is PlayerBufferingChanged && !event.buffering,
    );
    player.mediaStatus = const fvp.MediaStatus(fvp.MediaStatus.buffered);
    await recovered.timeout(const Duration(seconds: 2));
    expect(buffering.last, isFalse);
  });
}

// Implements the Dart API without loading MDK or a platform video texture.
class _FakePlayer implements fvp.Player {
  @override
  List<String> videoDecoders = [];
  @override
  double volume = 1;
  @override
  double playbackRate = 1;
  @override
  final textureId = ValueNotifier<int?>(null);
  int textureCount = 0;
  final rendererOperations = <String>[];
  Completer<void>? textureGate;
  final textureStarted = Completer<void>();
  bool disposed = false;
  fvp.PlaybackState nativeState = fvp.PlaybackState.stopped;
  bool delayStop = false;
  int currentPosition = 0;
  @override
  fvp.MediaStatus mediaStatus = const fvp.MediaStatus(fvp.MediaStatus.buffered);
  int prepares = 0;
  int initialPosition = 0;
  fvp.SeekFlag initialFlags = const fvp.SeekFlag(fvp.SeekFlag.defaultFlags);
  final changes = StreamController<
      ({fvp.PlaybackState oldValue, fvp.PlaybackState newValue})>.broadcast();
  final statuses = StreamController<
      ({fvp.MediaStatus oldValue, fvp.MediaStatus newValue})>.broadcast();

  void emitMediaStatus(fvp.MediaStatus status) => statuses.add((
        oldValue: const fvp.MediaStatus(fvp.MediaStatus.loaded),
        newValue: status,
      ));

  @override
  set state(fvp.PlaybackState value) {
    if (value == fvp.PlaybackState.stopped && !delayStop) {
      nativeState = value;
    }
  }

  @override
  Stream<({fvp.PlaybackState oldValue, fvp.PlaybackState newValue})>
      get onStateChanged => changes.stream;

  @override
  Stream<({fvp.MediaStatus oldValue, fvp.MediaStatus newValue})>
      get onMediaStatus => statuses.stream;

  @override
  Stream<fvp.MediaEvent> get onEvent => const Stream.empty();

  @override
  bool waitFor(fvp.PlaybackState state, {int timeout = -1}) {
    expectSync(timeout, 0);
    return nativeState == state;
  }

  @override
  Future<int> prepare({
    int position = 0,
    fvp.SeekFlag flags = const fvp.SeekFlag(fvp.SeekFlag.defaultFlags),
    Future<bool> Function()? callback,
    bool reply = false,
  }) async {
    expectSync(nativeState, fvp.PlaybackState.stopped);
    rendererOperations.add('prepare');
    prepares++;
    initialPosition = position;
    initialFlags = flags;
    nativeState = fvp.PlaybackState.paused;
    return position;
  }

  @override
  Future<int> updateTexture(
      {int? width, int? height, bool? tunnel, bool? fit}) async {
    if (textureId.value != null) {
      rendererOperations.add('release');
      textureId.value = null;
    }
    if (width == -1) return -1;
    rendererOperations.add('create');
    if (!textureStarted.isCompleted) textureStarted.complete();
    await textureGate?.future;
    textureId.value = ++textureCount;
    return textureId.value!;
  }

  @override
  fvp.MediaInfo get mediaInfo => _FakeMediaInfo();

  @override
  int get position => currentPosition;

  @override
  int buffered() => 1000;

  @override
  Future<void> dispose() async {
    disposed = true;
    await changes.close();
    await statuses.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeMediaInfo implements fvp.MediaInfo {
  @override
  int get duration => 60000;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

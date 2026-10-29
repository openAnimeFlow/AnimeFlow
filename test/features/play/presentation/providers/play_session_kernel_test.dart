import 'package:anime_flow/features/play/application/play_request.dart';
import 'package:anime_flow/features/play/application/play_session.dart';
import 'package:anime_flow/features/play/application/play_state.dart';
import 'package:anime_flow/features/play/domain/player/video_fit.dart';
import 'dart:async';
import 'dart:io';

import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/danmaku_session.dart';
import 'package:anime_flow/features/play/application/danmaku_state.dart';
import 'package:anime_flow/features/play/application/playback_coordinator.dart';
import 'package:anime_flow/features/play/application/playback_progress_manager.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => Storage.setting = _Settings());
  setUp(() => (Storage.setting as _Settings).stored.clear());

  test(
      'speed adjustments accumulate, clamp and restore correctly after temporary boost',
      () async {
    final state = _State();
    final session = _Session(_Factory(), state: state);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);

    session.adjustPlaybackRate(0.25);
    expect(state._value.rate, 1.25);
    session.setPlaybackRate(3, temporary: true);
    session.adjustPlaybackRate(0.25);
    session.adjustPlaybackRate(0.25);
    expect(state._value.rate, 3);
    expect(session.basePlaybackRate, 1.75);
    session.endTemporaryPlaybackRate();
    expect(state._value.rate, 1.75);

    session.adjustPlaybackRate(10);
    expect(state._value.rate, 4);
    session.adjustPlaybackRate(-10);
    expect(state._value.rate, 0.5);
    for (var i = 0; i < 5; i++) {
      session.adjustPlaybackRate(0.1);
    }
    expect(state._value.rate, 1);

    session.setPlaybackRate(3, temporary: true);
    session.setPlaybackRate(1);
    session.endTemporaryPlaybackRate();
    expect(state._value.rate, 1);
  });

  test('iOS opens local playback without a native storage channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('anime_flow/download_storage');
    var storageCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      storageCalls++;
      throw MissingPluginException(call.method);
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.initPlayState(_request(1));
    expect(storageCalls, 0);
    expect(factory.engines.last.source?.uri.toFilePath(), _localPath(1));
    expect(session.videoUrl, _localPath(1));
    expect(factory.engines.last.source?.isLocal, isTrue);
  });

  test('failed local opening allows retrying the same episode', () async {
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    factory.beforeOpen =
        (_) async => throw StateError('local file unavailable');
    await expectLater(session.initPlayState(_request(1)), throwsStateError);
    factory.beforeOpen = null;
    await session.initPlayState(_request(1));
    expect(factory.engines.last.source?.uri.toFilePath(), _localPath(1));
    expect(factory.engines.last.source?.isLocal, isTrue);
  });

  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.android,
    TargetPlatform.fuchsia,
  ]) {
    test('rebuilding preserves the correct engine volume on $platform',
        () async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final factory = _Factory();
      final state = _State()
        .._value = const PlayState(playing: true, volume: 35);
      final session = _Session(factory, state: state);
      await session.playbackCoordinator.initialize();
      addTearDown(session.playbackCoordinator.dispose);
      await session.initPlayState(_request(1));

      for (final enabled in [false, true, false]) {
        expect(await session.setHardwareDecoder(enabled), isTrue);
        expect(factory.engines.last.volume,
            platform == TargetPlatform.fuchsia ? 35 : 100);
        expect(state._value.volume, 35);
      }
      expect(await session.switchKernel(PlayerKernel.fvp), isTrue);
      expect(factory.engines.last.volume,
          platform == TargetPlatform.fuchsia ? 35 : 100);
    });
  }

  test(
      'hardware decoding defaults on and persists changes while rebuilding the same kernel',
      () async {
    final factory = _Factory();
    final state = _State()
      .._value = const PlayState(playing: true, videoFit: VideoFit.cover);
    final session = _Session(factory, state: state);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    expect(await session.setHardwareDecoder(true), isTrue);
    expect(factory.engines, hasLength(1));
    await session.initPlayState(_request(1));
    expect(await session.setHardwareDecoder(false), isTrue);
    expect(Storage.setting.get(PlaybackKey.hardwareDecoder), isFalse);
    expect(factory.engines, hasLength(2));
    expect(factory.engines.last.kernel, PlayerKernel.mediaKit);
    expect(factory.engines.first.disposeCount, 1);
    expect(factory.engines.last.source?.uri, Uri.file(_localPath(1)));
    expect(factory.engines.last.source?.isLocal, isTrue);
    expect(await session.setHardwareDecoder(true), isTrue);
    expect(Storage.setting.get(PlaybackKey.hardwareDecoder), isTrue);
    expect(factory.engines, hasLength(3));
    expect(factory.decoderOptions, [true, false, true]);
    expect(state._value.videoFit, VideoFit.cover);
  });

  test(
      'failed decoder rebuild rolls back settings and keeps the active engine options',
      () async {
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.initPlayState(_request(1));
    final original = factory.engines.single;
    factory.beforeOpen = (_) async => throw StateError('decoder unavailable');
    expect(await session.setHardwareDecoder(false), isFalse);
    expect(Storage.setting.get(PlaybackKey.hardwareDecoder), isTrue);
    expect(session.playbackCoordinator.hardwareDecoder, isTrue);
    expect(original.disposeCount, 0);
    expect(factory.engines.last.disposeCount, 1);
    factory.beforeOpen = null;
    expect(await session.switchKernel(PlayerKernel.fvp), isTrue);
    expect(factory.decoderOptions, [true, false, true]);
  });

  test('episode context stays on the old episode until switching finishes',
      () async {
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.initPlayState(_request(1));
    final started = Completer<void>();
    final gate = Completer<void>();
    factory.beforeOpen = (engine) async {
      if (engine.kernel == PlayerKernel.fvp && !started.isCompleted) {
        started.complete();
        await gate.future;
      }
    };

    final switching = session.switchKernel(PlayerKernel.fvp);
    await started.future;
    final episode = session.initPlayState(_request(2));
    await Future<void>.delayed(Duration.zero);
    expect(session.episodeId, 1);
    gate.complete();
    expect(await switching, isTrue);
    await episode;
    expect(session.episodeId, 2);
    expect(factory.engines.last.source?.uri, Uri.file(_localPath(2)));
    expect(factory.engines.first.source?.uri, Uri.file(_localPath(1)));
    expect(factory.engines.first.disposeCount, 1);
  });

  test('switch requested during episode opening snapshots the new episode',
      () async {
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.initPlayState(_request(1));
    final started = Completer<void>();
    final gate = Completer<void>();
    factory.beforeOpen = (engine) async {
      if (engine.kernel == PlayerKernel.mediaKit) {
        started.complete();
        await gate.future;
      }
    };

    final episode = session.initPlayState(_request(2));
    await started.future;
    final switching = session.switchKernel(PlayerKernel.fvp);
    await Future<void>.delayed(Duration.zero);
    expect(factory.engines, hasLength(1));
    gate.complete();
    await episode;
    expect(await switching, isTrue);
    expect(session.episodeId, 2);
    expect(factory.engines.last.source?.uri, Uri.file(_localPath(2)));
  });

  test('latest episode request wins when several arrive during switching',
      () async {
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.initPlayState(_request(1));
    final started = Completer<void>();
    final gate = Completer<void>();
    factory.beforeOpen = (engine) async {
      if (engine.kernel == PlayerKernel.fvp && !started.isCompleted) {
        started.complete();
        await gate.future;
      }
    };
    final switching = session.switchKernel(PlayerKernel.fvp);
    await started.future;
    final second = session.initPlayState(_request(2));
    final third = session.initPlayState(_request(3));
    gate.complete();
    await switching;
    await Future.wait([second, third]);
    expect(session.episodeId, 3);
    expect(factory.engines.last.openedUris, [
      Uri.file(_localPath(1)).toString(),
      Uri.file(_localPath(3)).toString(),
    ]);
  });

  test('manual seek stops before the end and moves the bar immediately',
      () async {
    const duration = Duration(minutes: 24);
    final factory = _Factory();
    final state = _State()
      .._value = const PlayState(
        playing: true,
        duration: duration,
        position: Duration(minutes: 10),
      );
    final session = _Session(factory, state: state);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.initPlayState(_request(1));

    session.seekTo(duration);
    await Future<void>.delayed(Duration.zero);

    final target = duration - const Duration(seconds: 1);
    expect(factory.engines.last.seekPositions, [target]);
    expect(state._value.position, target);
  });

  test('startup phase ignores play and seek requests', () async {
    final factory = _Factory();
    final state = _State()
      .._value = const PlayState(
        phase: PlaybackPhase.resolving,
        duration: Duration(minutes: 24),
      );
    final session = _Session(factory, state: state);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    final engine = factory.engines.single;

    session.playOrPauseVideo();
    expect(session.beginManualSeek(), isFalse);
    session.finishManualSeek(const Duration(minutes: 10));
    session.seekTo(const Duration(minutes: 10));
    await session.startPlaying();
    await Future<void>.delayed(Duration.zero);

    expect(engine.playCalls, 0);
    expect(engine.pauseCalls, 0);
    expect(engine.seekPositions, isEmpty);
    expect(state._value.position, Duration.zero);

    // 启动结束后恢复正常的播放与跳转。
    state._value = state._value.copyWith(
      phase: PlaybackPhase.playing,
      playing: true,
    );
    session.playOrPauseVideo();
    session.seekTo(const Duration(minutes: 10));
    await Future<void>.delayed(Duration.zero);

    expect(engine.pauseCalls, 1);
    expect(engine.seekPositions, [const Duration(minutes: 10)]);
  });
}

PlayRequest _request(int episode) => PlayRequest(
      videoUrl: _localPath(episode),
      offset: 0,
      subjectId: 1,
      episodeIndex: episode,
      episodeSort: episode,
      episodeId: episode,
      subjectName: 'test',
      subjectCover: '',
      alias: const [],
      isLocalPlayback: true,
    );

String _localPath(int episode) =>
    '${Directory.systemTemp.path}${Platform.pathSeparator}本地 #100% 第 $episode 集.mp4';

class _Session extends PlaySession {
  _Session(_Factory factory, {_State? state})
      : this._(factory, state ?? _State());

  _Session._(_Factory factory, _State state)
      : super(
          shadersDirectory: Directory.systemTemp,
          playStateActions: state,
          readPlayState: () => state._value,
          episodesActions: _Episodes(),
          danmaku: DanmakuSession(
            store: _DanmakuStore(),
            converter: DanmakuChineseConverter(),
            initialChineseMode: DanmakuChineseMode.none,
            readPlayback: () => const DanmakuPlaybackSnapshot(
              position: Duration.zero,
              duration: Duration.zero,
              playing: false,
            ),
            currentUserId: () => null,
          ),
          engineFactory: factory.create,
          setEpisodeWatched: (
              {required subjectId, required episodeId, required watched}) {},
        ) {
    playbackCoordinator = PlaybackCoordinator(
      engineFactory: factory.create,
      adBlocker: false,
      hardwareDecoder: true,
    );
    playbackProgressManager = _Progress();
  }
}

class _DanmakuStore implements DanmakuStore {
  @override
  DanmakuState get value => const DanmakuState();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Factory {
  final engines = <_Engine>[];
  final decoderOptions = <bool>[];
  Future<void> Function(_Engine)? beforeOpen;
  PlayerEngine create(PlayerKernel kernel,
      {required bool adBlocker, required bool hardwareDecoder}) {
    decoderOptions.add(hardwareDecoder);
    final engine = _Engine(kernel, this);
    engines.add(engine);
    return engine;
  }
}

class _Engine implements PlayerEngine {
  _Engine(this.kernel, this.factory);
  @override
  final PlayerKernel kernel;
  final _Factory factory;
  PlaybackSource? source;
  final openedUris = <String>[];
  final seekPositions = <Duration>[];
  int playCalls = 0;
  int pauseCalls = 0;
  int disposeCount = 0;
  double? volume;
  @override
  Stream<PlayerEvent> get events => const Stream.empty();
  @override
  Future<void> initialize() async {}
  @override
  Future<void> open(PlaybackSource source,
      {Duration? startPosition, bool autoPlay = false}) async {
    await factory.beforeOpen?.call(this);
    expect(disposeCount, 0, reason: 'must not open on a disposed engine');
    this.source = source;
    openedUris.add(source.uri.toString());
  }

  @override
  Future<void> play() async {
    expect(disposeCount, 0);
    playCalls++;
  }

  @override
  Future<void> pause() async {
    expect(disposeCount, 0);
    pauseCalls++;
  }

  @override
  Future<void> stop() async {
    expect(disposeCount, 0);
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> seek(Duration position) async {
    expect(disposeCount, 0);
    seekPositions.add(position);
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Settings implements Box<dynamic> {
  final stored = <dynamic, dynamic>{};
  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      stored[key] ?? defaultValue;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    stored[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _State implements PlayStateNotifier {
  PlayState _value = const PlayState(playing: true);
  @override
  void setRate(double rate) {
    _value = _value.copyWith(rate: rate);
  }

  @override
  void setKernel(PlayerKernel kernel) {
    _value = _value.copyWith(kernel: kernel);
  }

  @override
  void setSwitchingKernel(bool switching) {
    _value = _value.copyWith(switchingKernel: switching);
  }

  @override
  void setPosition(Duration position) {
    _value = _value.copyWith(position: position);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Episodes implements Episodes {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Progress implements PlaybackProgressManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

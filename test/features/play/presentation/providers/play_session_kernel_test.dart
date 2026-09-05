import 'dart:async';
import 'dart:io';

import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/playback_coordinator.dart';
import 'package:anime_flow/features/play/application/playback_progress_manager.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

void main() {
  setUpAll(() => Storage.setting = _Settings());
  setUp(() => (Storage.setting as _Settings).stored.clear());

  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.android,
    TargetPlatform.fuchsia,
  ]) {
    test('rebuilding preserves the correct engine volume on $platform', () async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final factory = _Factory();
      final state = _State()..value = const PlayState(playing: true, volume: 35);
      final session = _Session(factory, state: state);
      await session.playbackCoordinator.initialize();
      addTearDown(session.playbackCoordinator.dispose);
      await session.initPlayState(_request(1));

      for (final enabled in [false, true, false]) {
        expect(await session.setHardwareDecoder(enabled), isTrue);
        expect(factory.engines.last.volume,
            platform == TargetPlatform.fuchsia ? 35 : 100);
        expect(state.value.volume, 35);
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
    final session = _Session(factory);
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
    expect(
        factory.engines.last.source?.uri.toString(), 'https://example.com/1');
    expect(await session.setHardwareDecoder(true), isTrue);
    expect(Storage.setting.get(PlaybackKey.hardwareDecoder), isTrue);
    expect(factory.engines, hasLength(3));
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
    expect(
        factory.engines.last.source?.uri.toString(), 'https://example.com/2');
    expect(
        factory.engines.first.source?.uri.toString(), 'https://example.com/1');
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
    expect(
        factory.engines.last.source?.uri.toString(), 'https://example.com/2');
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
      'https://example.com/1',
      'https://example.com/3',
    ]);
  });
}

PlayRequest _request(int episode) => PlayRequest(
      videoUrl: 'https://example.com/$episode',
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

class _Session extends PlaySession {
  _Session(_Factory factory, {_State? state})
      : super(
          shadersDirectory: Directory.systemTemp,
          playStateActions: state ?? _State(),
          videoUiStateActions: _Ui(),
          episodesActions: _Episodes(),
          danmakuChineseConverter: DanmakuChineseConverter(),
          engineFactory: factory,
          initialDanmakuChineseMode: DanmakuChineseMode.none,
          setEpisodeWatched: (
              {required subjectId, required episodeId, required watched}) {},
        ) {
    playbackCoordinator =
        PlaybackCoordinator(engineFactory: factory, adBlocker: false);
    playbackProgressManager = _Progress();
  }
}

class _Factory extends PlayerEngineFactory {
  final engines = <_Engine>[];
  Future<void> Function(_Engine)? beforeOpen;
  @override
  PlayerEngine create(PlayerKernel kernel, {required bool adBlocker}) {
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
  }

  @override
  Future<void> pause() async {
    expect(disposeCount, 0);
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
  @override
  PlayState value = const PlayState(playing: true);
  @override
  void setKernel(PlayerKernel kernel) {
    value = value.copyWith(kernel: kernel);
  }

  @override
  void setSwitchingKernel(bool switching) {
    value = value.copyWith(switchingKernel: switching);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Ui implements VideoUiStateActions {
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

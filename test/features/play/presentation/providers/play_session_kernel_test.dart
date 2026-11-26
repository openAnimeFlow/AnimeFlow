import 'package:anime_flow/features/play/infrastructure/settings/stored_play_preferences.dart';
import 'package:anime_flow/features/play/infrastructure/history/hive_play_history_repository.dart';
import 'package:anime_flow/features/play/infrastructure/player/native_playback_platform.dart';
import 'package:anime_flow/features/play/infrastructure/danmaku/flow_danmaku_repository.dart';
import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/play_request.dart';
import 'package:anime_flow/features/play/application/play_session.dart';
import 'package:anime_flow/features/play/domain/play_state.dart';
import 'package:anime_flow/features/play/domain/player/video_fit.dart';
import 'dart:async';
import 'dart:io';

import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/core/settings/storage_key.dart';
import 'package:anime_flow/features/play/infrastructure/danmaku/opencc_converter.dart';
import 'package:anime_flow/features/play/domain/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/danmaku_session.dart';
import 'package:anime_flow/features/play/application/danmaku_state.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/features/play/application/playback_coordinator.dart';
import 'package:anime_flow/features/play/application/playback_progress_manager.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/domain/play_session_actions.dart';
import 'package:anime_flow/features/play/domain/play_history_repository.dart';
import 'package:anime_flow/shared/models/player/play/play_history_event_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => Storage.setting = _Settings());
  setUp(() => (Storage.setting as _Settings).stored.clear());

  test('replacement waits for old progress before resolving and stops once',
      () async {
    final factory = _Factory();
    final history = _PendingHistory();
    final session = _Session(factory, history: history);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.replacePlayback(() => _request(1));
    final engine = factory.engines.single;
    final progress = session.playbackProgressManager;
    progress.updatePlaybackState(
      position: const Duration(seconds: 73),
      duration: const Duration(minutes: 24),
      playing: true,
      isLoggedIn: false,
    );
    factory.onStop = () => progress.updatePlaybackState(
          position: Duration.zero,
          duration: Duration.zero,
          playing: false,
          isLoggedIn: false,
        );

    var resolving = false;
    final opening = session.replacePlayback(() async {
      resolving = true;
      final offset = await PlayHistoryService(history).resumePosition(1, 1);
      return _request(1, offset: offset);
    });
    final record = await history.started.future;
    expect(record.episodeId, 1);
    expect(record.position, 73);
    expect(resolving, isFalse);
    expect(engine.openedUris, hasLength(1));

    history.commit.complete();
    expect(await opening, isTrue);
    expect(engine.stopCalls, 1);
    expect(engine.startPositions.last, const Duration(seconds: 73));
  });

  test('a source resolved after a newer episode cannot reopen playback',
      () async {
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.replacePlayback(() => _request(1));
    final engine = factory.engines.single;
    final resolving = Completer<void>();
    final delayed = Completer<PlayRequest>();
    final old = session.replacePlayback(() {
      resolving.complete();
      return delayed.future;
    });
    await resolving.future;
    await session.replacePlayback(() => _request(3));
    delayed.complete(_request(2));
    expect(await old, isFalse);
    expect(engine.stopCalls, 1);
    expect(engine.openedUris, [
      Uri.file(_localPath(1)).toString(),
      Uri.file(_localPath(3)).toString(),
    ]);
  });

  test('a request invalidated during creation releases the unopened player',
      () async {
    final creating = Completer<void>();
    final finishCreation = Completer<void>();
    final factory = _Factory()
      ..beforeCreate = () async {
        creating.complete();
        await finishCreation.future;
      };
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    var isCurrent = true;

    final opening = session.replacePlayback(() => _request(1),
        shouldUseResult: () => isCurrent);
    await creating.future;
    isCurrent = false;
    finishCreation.complete();

    expect(await opening, isFalse);
    final engine = factory.engines.single;
    expect(engine.openedUris, isEmpty);
    expect(engine.stopCalls, 1);
  });

  test('local source remains local after opening and kernel switches',
      () async {
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.replacePlayback(() => PlayRequest(
          source: PlaybackSource.localFile(
              Directory.systemTemp.uri.resolve('sample.mkv').toFilePath()),
          offset: 0,
          subjectId: 1,
          episodeIndex: 1,
          episodeSort: 1,
          episodeId: 1,
          subjectName: 'Anime',
          subjectCover: '',
          alias: const [],
        ));
    expect(factory.engines.last.source, isA<LocalFilePlaybackSource>());
    expect(await session.switchKernel(PlayerKernel.fvp), isTrue);
    expect(factory.engines.last.source, isA<LocalFilePlaybackSource>());
  });

  test('failed native validation never starts playback', () async {
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    factory.beforeOpen = (_) async => throw StateError('unsupported codec');
    await expectLater(
        session.replacePlayback(() => _request(1)), throwsStateError);
    expect(factory.engines.single.playCalls, 0);
  });

  test('superseded source does not start playing after native open completes',
      () async {
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    final started = Completer<void>();
    final gate = Completer<void>();
    factory.beforeOpen = (_) async {
      started.complete();
      await gate.future;
    };
    var current = true;
    final opening = session.replacePlayback(() => _request(1),
        shouldUseResult: () => current);
    await started.future;
    current = false;
    gate.complete();
    await opening;
    expect(factory.engines.single.playCalls, 0);
  });

  test(
      'upscale selection survives episodes, decoder rebuilds and kernel round trips',
      () async {
    final factory = _Factory();
    final state = _State();
    final session = _Session(factory, state: state);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.replacePlayback(() => _request(1));
    await session.setUpscalePreset(UpscalePreset.quality);
    await session.replacePlayback(() => _request(2));
    expect(factory.engines.last.upscalePreset, UpscalePreset.quality);
    expect(await session.setHardwareDecoder(false), isTrue);
    expect(factory.engines.last.upscalePreset, UpscalePreset.quality);
    expect(await session.switchKernel(PlayerKernel.fvp), isTrue);
    expect(factory.engines.last.upscalePreset, UpscalePreset.off);
    expect(state._value.upscalePreset, UpscalePreset.quality);
    expect(await session.switchKernel(PlayerKernel.mediaKit), isTrue);
    expect(factory.engines.last.upscalePreset, UpscalePreset.quality);
  });

  test(
      'failed and unsupported upscale selections preserve state; off works on any kernel',
      () async {
    final factory = _Factory();
    final state = _State();
    final session = _Session(factory, state: state);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.setUpscalePreset(UpscalePreset.efficiency);
    factory.engines.last.failUpscale = true;
    await expectLater(
        session.setUpscalePreset(UpscalePreset.quality), throwsStateError);
    expect(state._value.upscalePreset, UpscalePreset.efficiency);
    expect(await session.switchKernel(PlayerKernel.fvp), isTrue);
    await expectLater(session.setUpscalePreset(UpscalePreset.quality),
        throwsUnsupportedError);
    expect(state._value.upscalePreset, UpscalePreset.efficiency);
    await session.setUpscalePreset(UpscalePreset.off);
    expect(state._value.upscalePreset, UpscalePreset.off);
    expect(await session.switchKernel(PlayerKernel.mediaKit), isTrue);
    expect(factory.engines.last.upscalePreset, UpscalePreset.off);
  });

  test('upscale changes queued during a kernel switch apply to the new engine',
      () async {
    final factory = _Factory();
    final state = _State();
    final session = _Session(factory, state: state);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session.replacePlayback(() => _request(1));
    await session.setUpscalePreset(UpscalePreset.quality);
    final started = Completer<void>();
    final gate = Completer<void>();
    factory.beforeOpen = (_) async {
      started.complete();
      await gate.future;
    };
    final switching = session.switchKernel(PlayerKernel.fvp);
    await started.future;
    final disabling = session.setUpscalePreset(UpscalePreset.off);
    expect(state._value.upscalePreset, UpscalePreset.quality);
    gate.complete();
    expect(await switching, isTrue);
    await disabling;
    expect(state._value.upscalePreset, UpscalePreset.off);
    expect(factory.engines.first.upscalePreset, UpscalePreset.quality);
    expect(factory.engines.last.upscalePreset, UpscalePreset.off);
  });

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
    await session.replacePlayback(() => _request(1));
    expect(storageCalls, 0);
    expect(factory.engines.last.source?.uri.toFilePath(), _localPath(1));
    expect(factory.engines.last.source, isA<LocalFilePlaybackSource>());
  });

  test('failed local opening allows retrying the same episode', () async {
    final factory = _Factory();
    final session = _Session(factory);
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    factory.beforeOpen =
        (_) async => throw StateError('local file unavailable');
    await expectLater(
        session.replacePlayback(() => _request(1)), throwsStateError);
    factory.beforeOpen = null;
    await session.replacePlayback(() => _request(1));
    expect(factory.engines.last.source?.uri.toFilePath(), _localPath(1));
    expect(factory.engines.last.source, isA<LocalFilePlaybackSource>());
  });

  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
    TargetPlatform.android,
    TargetPlatform.iOS,
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
      await session.replacePlayback(() => _request(1));

      for (final enabled in [false, true, false]) {
        expect(await session.setHardwareDecoder(enabled), isTrue);
        expect(
            factory.engines.last.volume,
            platform == TargetPlatform.android || platform == TargetPlatform.iOS
                ? 100
                : 35);
        expect(state._value.volume, 35);
      }
      expect(await session.switchKernel(PlayerKernel.fvp), isTrue);
      expect(
          factory.engines.last.volume,
          platform == TargetPlatform.android || platform == TargetPlatform.iOS
              ? 100
              : 35);
    });
  }

  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ]) {
    test('volume adjustments do not change system volume on $platform',
        () async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('com.kurenai7968.volume_controller.method');
      var systemCalls = 0;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async {
        systemCalls++;
        return 0.5;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final factory = _Factory();
      final state = _State().._value = const PlayState(volume: 35);
      final session = _Session(factory, state: state);
      session.systemVolumeSynchronizer = session.platform.createVolume((_) {});
      await session.playbackCoordinator.initialize();
      addTearDown(session.playbackCoordinator.dispose);
      addTearDown(session.systemVolumeSynchronizer.dispose);
      await session.systemVolumeSynchronizer.initialize();
      session.adjustVolumeByWheel(10);
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(state._value.volume, 45);
      expect(factory.engines.last.volume, 45);
      expect(systemCalls, 0);
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
    await session.replacePlayback(() => _request(1));
    expect(await session.setHardwareDecoder(false), isTrue);
    expect(Storage.setting.get(PlaybackKey.hardwareDecoder), isFalse);
    expect(factory.engines, hasLength(2));
    expect(factory.engines.last.kernel, PlayerKernel.mediaKit);
    expect(factory.engines.first.disposeCount, 1);
    expect(factory.engines.last.source?.uri, Uri.file(_localPath(1)));
    expect(factory.engines.last.source, isA<LocalFilePlaybackSource>());
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
    await session.replacePlayback(() => _request(1));
    final original = factory.engines.single;
    factory.beforeOpen = (_) async => throw StateError('decoder unavailable');
    expect(await session.setHardwareDecoder(false), isFalse);
    expect(Storage.setting.get(PlaybackKey.hardwareDecoder), isTrue);
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
    await session.replacePlayback(() => _request(1));
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
    final episode = session.replacePlayback(() => _request(2));
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
    await session.replacePlayback(() => _request(1));
    final started = Completer<void>();
    final gate = Completer<void>();
    factory.beforeOpen = (engine) async {
      if (engine.kernel == PlayerKernel.mediaKit) {
        started.complete();
        await gate.future;
      }
    };

    final episode = session.replacePlayback(() => _request(2));
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
    await session.replacePlayback(() => _request(1));
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
    final second = session.replacePlayback(() => _request(2));
    final third = session.replacePlayback(() => _request(3));
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
    await session.replacePlayback(() => _request(1));

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

PlayRequest _request(int episode, {int offset = 0}) => PlayRequest(
      source: PlaybackSource.localFile(_localPath(episode)),
      offset: offset,
      subjectId: 1,
      episodeIndex: episode,
      episodeSort: episode,
      episodeId: episode,
      subjectName: 'test',
      subjectCover: '',
      alias: const [],
    );

String _localPath(int episode) =>
    '${Directory.systemTemp.path}${Platform.pathSeparator}本地 #100% 第 $episode 集.mp4';

class _Session extends PlaySession {
  _Session(_Factory factory, {_State? state, PlayHistoryRepository? history})
      : this._(factory, state ?? _State(), history);

  _Session._(_Factory factory, _State state, PlayHistoryRepository? history)
      : super(
          preferences: StoredPlayPreferences(),
          platform: NativePlaybackPlatform(),
          history: history ?? HivePlayHistoryRepository(),
          markEpisodeWatched: (_) async {},
          playStateActions: state,
          readPlayState: () => state._value,
          episodesActions: _Episodes(),
          danmaku: DanmakuSession(
            repository: FlowDanmakuRepository(),
            useDanmakuColor: () => true,
            saveEnabled: (_) {},
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
    playbackProgressManager = history == null
        ? _Progress()
        : PlaybackProgressManager(
            history: history,
            autoMarkEnabled: () => false,
            markEpisodeWatched: (_) async {},
            onEpisodeWatched: (
                {required subjectId, required episodeId, required watched}) {},
          );
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
  Future<void> Function()? beforeCreate;
  Future<void> Function(_Engine)? beforeOpen;
  void Function()? onStop;
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
  PlaybackSource? _pendingSource;
  final openedUris = <String>[];
  final startPositions = <Duration?>[];
  final seekPositions = <Duration>[];
  int playCalls = 0;
  int pauseCalls = 0;
  int stopCalls = 0;
  int disposeCount = 0;
  double? volume;
  UpscalePreset upscalePreset = UpscalePreset.off;
  bool failUpscale = false;
  @override
  PlayerCapabilities get capabilities => PlayerCapabilities(
        supportedUpscalePresets: kernel == PlayerKernel.mediaKit
            ? const {UpscalePreset.efficiency, UpscalePreset.quality}
            : const {},
      );
  @override
  Future<void> setUpscalePreset(UpscalePreset preset) async {
    if (failUpscale) throw StateError('upscale failed');
    upscalePreset = preset;
  }

  @override
  Stream<PlayerEvent> get events => const Stream.empty();
  @override
  Future<void> initialize() async {}
  @override
  Future<void> createPlayer(PlaybackSource source) async {
    expect(disposeCount, 0, reason: 'must not create on a disposed engine');
    await factory.beforeCreate?.call();
    _pendingSource = source;
  }

  @override
  Future<void> open({Duration? startPosition, bool autoPlay = false}) async {
    await factory.beforeOpen?.call(this);
    expect(disposeCount, 0, reason: 'must not open on a disposed engine');
    final source = _pendingSource!;
    _pendingSource = null;
    this.source = source;
    openedUris.add(source.uri.toString());
    startPositions.add(startPosition);
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
    stopCalls++;
    factory.onStop?.call();
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

class _State implements PlayStateActions {
  PlayState _value = const PlayState(playing: true);
  @override
  void setVolume(double volume) {
    _value = _value.copyWith(volume: volume);
  }

  @override
  void setUpscalePreset(UpscalePreset preset) {
    _value = _value.copyWith(upscalePreset: preset);
  }

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

class _Episodes implements EpisodeActions {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Progress implements PlaybackProgressManager {
  @override
  Future<void> save({
    Duration? position,
    PlayHistoryEventType eventType = PlayHistoryEventType.defaults,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PendingHistory implements PlayHistoryRepository {
  final started = Completer<PlaybackRecord>();
  final commit = Completer<void>();
  PlaybackRecord? _record;

  @override
  Future<void> save(PlaybackRecord record,
      {required PlayHistoryEventType eventType}) async {
    started.complete(record);
    await commit.future;
    _record = record;
  }

  @override
  Future<PlaybackRecord?> getBySubjectId(int subjectId) async => _record;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

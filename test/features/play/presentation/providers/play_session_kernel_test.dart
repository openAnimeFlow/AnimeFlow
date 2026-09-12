import 'dart:async';
import 'dart:io';

import 'package:anime_flow/features/media_cache/application/hls_media_cache.dart';
import 'package:anime_flow/features/media_cache/application/shared_media_cache.dart';
import 'package:anime_flow/features/media_cache/domain/hls_snapshot.dart';

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
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:hive_ce/hive.dart';
import 'package:anime_flow/features/recording/application/recording_controller.dart';
import 'package:anime_flow/features/recording/application/recording_service.dart';
import 'package:anime_flow/features/recording/domain/recording_backend.dart';
import 'package:anime_flow/shared/models/player/play/play_history_event_type.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import '../../../recording/recording_test_support.dart';

void main() {
  setUpAll(() => Storage.setting = _Settings());
  setUp(() => (Storage.setting as _Settings).stored.clear());

  for (final action in ['seek', 'pause', 'episode', 'cover', 'background']) {
    test('recording freezes old media interval before $action', () async {
      final root = await Directory.systemTemp.createTemp('recording-session-');
      final backend = ControlledRecordingBackend();
      final service = RecordingService(directory: root, backend: backend);
      final recorder = RecordingController(serviceFactory: () async => service);
      final state = _State();
      final factory = _Factory();
      final session = _Session(factory, state: state, recorder: recorder);
      await session.playbackCoordinator.initialize();
      await session.initPlayState(_request(1));
      state.value = state.value.copyWith(position: const Duration(seconds: 10));
      await session.toggleRecording();
      recorder.updatePosition(const Duration(seconds: 13));
      state.value = state.value.copyWith(position: const Duration(seconds: 13));
      switch (action) {
        case 'seek':
          session.seekTo(const Duration(seconds: 50));
        case 'pause':
          session.playOrPauseVideo();
        case 'episode':
          await session.initPlayState(_request(2));
        case 'cover':
          session.pauseForRouteCover();
        case 'background':
          session.didChangeAppLifecycleState(AppLifecycleState.paused);
      }
      expect(service.tasks.single.start, const Duration(seconds: 10));
      expect(service.tasks.single.end, const Duration(seconds: 13));
      expect(recorder.active, isFalse);
      await eventually(() => backend.handles.isNotEmpty);
      backend.handles.single.finish(ExportStatus.cancelled);
      await eventually(() => !service.tasks.single.busy);
      await service.remove(service.tasks.single);
      recorder.dispose();
      await session.playbackCoordinator.dispose();
      await root.delete(recursive: true);
    });
  }

  test('kernel switch preserves an active marker on the same source', () async {
    final root = await Directory.systemTemp.createTemp('recording-kernel-');
    final backend = ControlledRecordingBackend();
    final service = RecordingService(directory: root, backend: backend);
    final recorder = RecordingController(serviceFactory: () async => service);
    final factory = _Factory();
    final session = _Session(factory, recorder: recorder);
    await session.playbackCoordinator.initialize();
    await session.initPlayState(_request(1));
    await session.toggleRecording();
    expect(await session.switchKernel(PlayerKernel.fvp), isTrue);
    expect(recorder.value.status, RecordingMarkerStatus.marking);
    recorder.dispose(); // No progress means no task.
    expect(service.tasks, isEmpty);
    await session.playbackCoordinator.dispose();
    await root.delete(recursive: true);
  });

  test('cache stays opt-in and direct sources retain authentication headers',
      () async {
    final factory = _Factory();
    final session = _Session(factory,
        cacheFactory: () async => throw StateError('Must not create cache'));
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session
        .initPlayState(_networkRequest('https://example.test/index.m3u8'));
    expect(
        factory.engines.single.source!.headers['Authorization'], 'Bearer test');
    expect(session.cacheStatus.value, MediaCacheIssue.disabled);
  });

  test('ad filtering disables cache without switching player kernel', () async {
    await Storage.setting.put(PlaybackKey.sharedMediaCache, true);
    final factory = _Factory();
    final session = _Session(factory,
        adBlocker: true,
        cacheFactory: () async => throw StateError('Must not create cache'));
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session
        .initPlayState(_networkRequest('https://example.test/index.m3u8'));
    expect(session.cacheStatus.value, MediaCacheIssue.timelineChanged);
    expect(factory.engines, hasLength(1));
    expect(factory.engines.single.source!.uri.host, 'example.test');
  });

  test('unsupported cache source falls back to its authenticated direct source',
      () async {
    await Storage.setting.put(PlaybackKey.sharedMediaCache, true);
    final factory = _Factory();
    final session = _Session(factory,
        cacheFactory: () async => throw const MediaCacheException(
            MediaCacheIssue.unsupported, 'unsupported'));
    await session.playbackCoordinator.initialize();
    addTearDown(session.playbackCoordinator.dispose);
    await session
        .initPlayState(_networkRequest('https://example.test/index.m3u8'));
    expect(session.cacheStatus.value, MediaCacheIssue.unsupported);
    expect(
        factory.engines.single.source!.headers['Authorization'], 'Bearer test');
  });

  for (final stale in [false, true]) {
    test('network cache lifecycle with kernel switch and stale source=$stale',
        () async {
      await Storage.setting.put(PlaybackKey.sharedMediaCache, true);
      final directory =
          await Directory.systemTemp.createTemp('play-cache-test-');
      final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final cache = HlsMediaCache(directory: directory);
      final started = Completer<void>();
      final gate = Completer<void>();
      origin.listen((request) async {
        if (request.uri.path.endsWith('.m3u8')) {
          request.response.write(
              '#EXTM3U\n#EXT-X-TARGETDURATION:2\n#EXTINF:2,\ns.ts\n#EXT-X-ENDLIST\n');
        } else {
          if (!started.isCompleted) started.complete();
          if (stale) await gate.future;
          final bytes = Uint8List(564);
          bytes[0] = bytes[188] = bytes[376] = 0x47;
          request.response.add(bytes);
        }
        await request.response.close();
      });
      final factory = _Factory();
      final session = _Session(factory, cacheFactory: () async => cache);
      await session.playbackCoordinator.initialize();
      try {
        final opening = session.initPlayState(
            _networkRequest('http://127.0.0.1:${origin.port}/index.m3u8'));
        await started.future;
        if (stale) {
          final next = session.initPlayState(_request(2));
          gate.complete();
          await Future.wait([opening, next]);
          expect(session.cacheSession, isNull);
          expect(cache.cachedBytes, 0);
          expect(factory.engines.single.source!.isLocal, isTrue);
        } else {
          await opening;
          final sourceSession = session.cacheSession!;
          final lease = sourceSession.retainRange(
              Duration.zero, const Duration(seconds: 2));
          final uri = factory.engines.single.source!.uri;
          expect(factory.engines.single.source!.headers, isEmpty);
          expect(await session.switchKernel(PlayerKernel.fvp), isTrue);
          expect(factory.engines.last.source!.uri, uri);
          expect(session.cacheSession, same(sourceSession));
          await session.stopCurrentMedia();
          expect(await sourceSession.directory.exists(), isTrue);
          await lease.release();
          expect(await sourceSession.directory.exists(), isFalse);
        }
      } finally {
        if (!gate.isCompleted) gate.complete();
        await session.stopCurrentMedia();
        await session.playbackCoordinator.dispose();
        await cache.close();
        await origin.close(force: true);
        await directory.delete(recursive: true);
      }
    });
  }

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
        ..value = const PlayState(playing: true, volume: 35);
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
    expect(factory.engines.last.source?.uri, Uri.file(_localPath(1)));
    expect(factory.engines.last.source?.isLocal, isTrue);
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

PlayRequest _networkRequest(String url) => PlayRequest(
    videoUrl: url,
    offset: 0,
    subjectId: 0,
    episodeIndex: 0,
    episodeSort: 0,
    episodeId: 0,
    subjectName: 'test',
    subjectCover: '',
    alias: const [],
    headers: const {'Authorization': 'Bearer test'});

String _localPath(int episode) =>
    '${Directory.systemTemp.path}${Platform.pathSeparator}本地 #100% 第 $episode 集.mp4';

class _Session extends PlaySession {
  _Session(_Factory factory,
      {_State? state,
      RecordingController? recorder,
      bool adBlocker = false,
      Future<HlsMediaCache> Function()? cacheFactory})
      : super(
          recordingController: recorder,
          mediaCacheFactory: cacheFactory ?? sharedMediaCache,
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
        PlaybackCoordinator(engineFactory: factory, adBlocker: adBlocker);
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
  Future<void> seek(Duration position) async {}
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
  VideoControlsIndicatorType get currentIndicatorType =>
      VideoControlsIndicatorType.noIndicator;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Episodes implements Episodes {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Progress implements PlaybackProgressManager {
  @override
  Future<void> save(
      {Duration? position,
      PlayHistoryEventType eventType = PlayHistoryEventType.defaults}) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

import 'dart:async';
import 'dart:io';

import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/playback_progress_manager.dart';
import 'package:anime_flow/features/play/application/playback_coordinator.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_engine_factory.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  setUpAll(() => Storage.setting = _Settings());

  test(
      'new episode loads while old conversion is pending and rejects old result',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('danmaku_request_test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/danmaku.json');
    await file.writeAsString('[{"m":"test","p":"1,1,16777215,test"}]');
    final converter = _Converter();
    final session = _Session(converter);
    final first = session.initPlayState(_request(1, file.path));
    await converter.started.future;
    await session.initPlayState(_request(2, file.path));
    expect(converter.calls, 2);
    expect(session.installs, 1);
    converter.gate.complete();
    await first;
    expect(session.installs, 1);
  });

  test('stopping during conversion prevents installing the pending result',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('danmaku_stop_test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/danmaku.json');
    await file.writeAsString('[{"m":"test","p":"1,1,16777215,test"}]');
    final converter = _Converter();
    final session = _Session(converter);
    final opening = session.initPlayState(_request(1, file.path));
    await converter.started.future;
    await session.stopCurrentMedia();
    converter.gate.complete();
    await opening;
    expect(session.installs, 0);
  });
}

PlayRequest _request(int episode, String path) => PlayRequest(
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
      localDanmakuPath: path,
    );

class _Session extends PlaySession {
  _Session(DanmakuChineseConverter converter)
      : super(
          shadersDirectory: Directory.systemTemp,
          playStateActions: _State(),
          videoUiStateActions: _Ui(),
          episodesActions: _Episodes(),
          danmakuChineseConverter: converter,
          engineFactory: const PlayerEngineFactory(),
          initialDanmakuChineseMode: DanmakuChineseMode.none,
          setEpisodeWatched: (
              {required subjectId, required episodeId, required watched}) {},
        ) {
    playbackProgressManager = _Progress();
    playbackCoordinator = PlaybackCoordinator(
        engineFactory: _EngineFactory(_engine), adBlocker: false);
    unawaited(playbackCoordinator.initialize());
  }
  int installs = 0;
  final _engine = _Engine();
  @override
  void addDanmakuAll(List<Danmaku> danmaku) {
    installs++;
  }
}

class _Converter extends DanmakuChineseConverter {
  final started = Completer<void>();
  final gate = Completer<void>();
  int calls = 0;
  @override
  Future<List<Danmaku>> convertDanmakus(
      List<Danmaku> items, DanmakuChineseMode mode) async {
    if (++calls == 1) {
      started.complete();
      await gate.future;
    }
    return items;
  }
}

class _Engine implements PlayerEngine {
  @override
  Future<void> initialize() async {}
  @override
  Stream<PlayerEvent> get events => const Stream.empty();
  @override
  Future<void> stop() async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> open(PlaybackSource source,
      {Duration? startPosition, bool autoPlay = false}) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _EngineFactory extends PlayerEngineFactory {
  const _EngineFactory(this.engine);
  final PlayerEngine engine;
  @override
  PlayerEngine create(kernel, {required bool adBlocker}) => engine;
}

class _Settings implements Box<dynamic> {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _State implements PlayStateNotifier {
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

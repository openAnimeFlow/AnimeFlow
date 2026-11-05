import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/play/composition/play_overrides.dart';
import 'dart:async';

import 'package:anime_flow/shared/navigation/args/play_route_extra.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_state_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

@Dependencies([
  playSession,
  VideoSourceNotifier,
  PlayStateNotifier,
  DanmakuStateNotifier,
  VideoUiNotifier,
  Episodes,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer root;
  late List<_Engine> engines;
  setUpAll(() => Storage.setting = _Settings());

  setUp(() {
    // 本测试只验证 Provider 生命周期，不调用原生音量和亮度接口。
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    engines = [];
    root = ProviderContainer(overrides: [
      ...playFeatureOverrides,
      playerEngineFactoryProvider.overrideWithValue((kernel,
          {required adBlocker, required hardwareDecoder}) {
        final engine = _Engine(kernel);
        engines.add(engine);
        return engine;
      }),
      videoUiProvider.overrideWith(_VideoUi.new),
    ]);
  });
  tearDown(() {
    root.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  ProviderContainer route(int id, {List<DownloadEpisode> episodes = const []}) {
    final container = ProviderContainer(parent: root, overrides: [
      playExtraProvider.overrideWithValue(PlayRouteExtra(
        playExtra: PlayExtra(
          subjectId: id,
          subjectName: 'Subject $id',
          subjectCover: '',
          subjectAliases: const [],
        ),
        isOfflineMode: true,
        offlineEpisodes: episodes,
      )),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('page subscriptions retain hidden playback and release the whole chain',
      () async {
    final container = route(1);
    final sourceOwner =
        container.listen(videoSourceProvider.notifier, (_, __) {});
    final sessionOwner = container.listen(playSessionProvider, (_, __) {});
    final session = sessionOwner.read();
    final source = sourceOwner.read();
    final ui = container.listen(playStateProvider, (_, __) {});
    await container.read(episodesProvider.future);
    container.read(playStateProvider.notifier).setRate(1.5);
    container.read(videoUiProvider.notifier).hideControlsUi();

    // 移除控件的监听后，不应重置播放会话或界面状态。
    ui.close();
    await container.pump();
    expect(container.read(playSessionProvider), same(session));
    expect(container.read(videoSourceProvider.notifier), same(source));
    expect(container.read(playStateProvider).rate, 1.5);
    expect(container.read(videoUiProvider).isShowControlsUi, isFalse);
    expect(engines.single.disposed.isCompleted, isFalse);

    // 视频源选择器暂时移除后，页面仍可继续持有播放会话。
    sourceOwner.close();
    await container.pump();
    expect(container.exists(videoSourceProvider), isFalse);
    expect(engines.single.disposed.isCompleted, isFalse);

    sessionOwner.close();
    await container.pump();
    await engines.single.disposed.future;
    await container.pump();
    expect(container.exists(playSessionProvider), isFalse);
    expect(container.exists(playStateProvider), isFalse);
    expect(container.exists(danmakuStateProvider), isFalse);
    expect(container.exists(videoUiProvider), isFalse);
    expect(container.exists(episodesProvider), isFalse);
    expect(engines.single.disposeCount, 1);
  });

  test('completion advances an offline episode and stops at the last one',
      () async {
    FlutterSecureStorage.setMockInitialValues({});
    Storage.playHistory = _EmptyHistory();
    final container = route(1, episodes: [
      for (final id in [101, 102])
        DownloadEpisode(
          episodeUrl: 'ep$id',
          bangumiEpisodeId: id,
          episodeSort: (id - 100).toDouble(),
          episodeIndex: id - 100,
          episodeTitle: 'Episode $id',
          lineIndex: 0,
          sourceName: 'local',
          status: DownloadStatus.completed,
          localMediaPath: '/ep$id.mp4',
        ),
    ]);
    final session = container.listen(playSessionProvider, (_, __) {}).read();
    session.subjectId = 1;
    await session.playbackCoordinator.initialize();
    expect((await container.read(episodesProvider.future)).episodeId, 101);
    // 播放完成会清除续播记录，模拟安全存储需要受支持的平台。
    final originalPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = originalPlatform);

    Future<void> completeEpisode() async {
      final completed = session.playbackCoordinator.events
          .firstWhere((event) => event is PlayerCompleted);
      engines.single.eventController.add(const PlayerCompleted());
      await completed;
      await container.pump();
    }

    await completeEpisode();
    expect(container.read(playStateProvider).phase, PlaybackPhase.completed);
    expect(container.read(episodesProvider).requireValue.episodeId, 102);
    await completeEpisode();
    expect(container.read(episodesProvider).requireValue.episodeId, 102);
  });

  test('disposing an old playback route preserves the next route session',
      () async {
    final oldRoute = route(1);
    final newRoute = route(2);
    oldRoute.listen(playSessionProvider, (_, __) {});
    final owner = newRoute.listen(playSessionProvider, (_, __) {});
    final nextSession = owner.read();
    newRoute.read(playStateProvider.notifier).setRate(2);
    await Future<void>.delayed(Duration.zero);

    oldRoute.dispose();
    await engines.first.disposed.future;
    expect(engines.last.disposed.isCompleted, isFalse);
    expect(newRoute.read(playSessionProvider), same(nextSession));
    expect(newRoute.read(playStateProvider).rate, 2);

    owner.close();
    await newRoute.pump();
    await engines.last.disposed.future;
    expect(engines.map((engine) => engine.disposeCount), [1, 1]);
  });
}

class _VideoUi extends VideoUiNotifier {
  @override
  VideoUiState build() => const VideoUiState();
}

class _Engine implements PlayerEngine {
  _Engine(this.kernel);
  @override
  final PlayerKernel kernel;
  final disposed = Completer<void>();
  final eventController = StreamController<PlayerEvent>.broadcast();
  int disposeCount = 0;
  @override
  PlayerCapabilities get capabilities => const PlayerCapabilities();
  @override
  Stream<PlayerEvent> get events => eventController.stream;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> dispose() async {
    await eventController.close();
    disposeCount++;
    disposed.complete();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings implements Box<dynamic> {
  @override
  dynamic get(dynamic key, {dynamic defaultValue}) => defaultValue;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyHistory implements Box<PlayHistory> {
  @override
  PlayHistory? get(dynamic key, {PlayHistory? defaultValue}) => defaultValue;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

import 'dart:async';

import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/user/user_api.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_converter.dart';
import 'package:anime_flow/features/play/application/danmaku_chinese_mode.dart';
import 'package:anime_flow/features/play/application/danmaku_session.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_chinese_mode_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_state_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/subject_episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'player_bindings.g.dart';

final playerEngineFactoryProvider = Provider<PlayerEngineFactory>(
  (ref) =>
      throw StateError('PlayerEngineFactory must be configured by the app'),
);

/// 在装配处将业务会话连接到路由内的状态和 UI 实现。
@Riverpod(
  dependencies: [
    playExtra,
    PlayStateNotifier,
    DanmakuStateNotifier,
    VideoUiNotifier,
    Episodes,
  ],
)
PlaySession playSession(Ref ref) {
  ref.watch(playExtraProvider);
  // 模式变化由下方 ref.listen 处理，不能 watch 重建整个播放会话。
  final initialDanmakuChineseMode = ref.read(danmakuChineseModeProvider);
  final playStateActions = ref.watch(playStateProvider.notifier);
  final danmaku = DanmakuSession(
    store: ref.watch(danmakuStateProvider.notifier),
    converter: ref.watch(danmakuChineseConverterProvider),
    initialChineseMode: initialDanmakuChineseMode,
    readPlayback: () {
      final state = ref.read(playStateProvider);
      return DanmakuPlaybackSnapshot(
        position: state.position,
        duration: state.duration,
        playing: state.playing,
      );
    },
    currentUserId: () => ref.read(currentUserInfoProvider).value?.id,
  );
  // 保留路由内的 UI 状态，控件暂时隐藏时仍能响应播放状态变化。
  ref.watch(videoUiProvider.notifier);
  final controller = PlaySession(
    shadersDirectory: ref.watch(shadersDirectoryProvider).requireValue,
    playStateActions: playStateActions,
    readPlayState: () => ref.read(playStateProvider),
    episodesActions: ref.watch(episodesProvider.notifier),
    danmaku: danmaku,
    engineFactory: ref.read(playerEngineFactoryProvider),
    setEpisodeWatched: ({
      required subjectId,
      required episodeId,
      required watched,
    }) {
      if (!ref.mounted) return;
      ref.read(subjectEpisodesProvider(subjectId).notifier).setEpisodeWatched(
            episodeId: episodeId,
            watched: watched,
          );
    },
  )..init();

  ref.listen<DanmakuChineseMode>(
    danmakuChineseModeProvider,
    (previous, next) {
      if (previous != next) {
        unawaited(danmaku.applyChineseMode(next));
      }
    },
  );

  ref.listen<PlayState>(
    playStateProvider,
    (previous, next) {
      controller.handlePlayStateChanged(
        next,
        isLoggedIn: ref.read(isLoggedInProvider).value ?? false,
      );
    },
  );
  ref.onDispose(controller.dispose);

  return controller;
}

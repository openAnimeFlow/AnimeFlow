import 'dart:async';

import 'package:anime_flow/features/play/application/video_source_workflow.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/features/play/application/video_source_state.dart';
import 'package:anime_flow/features/play/domain/play_source_repository.dart';
import 'package:anime_flow/features/play/domain/local_video_files.dart';
import 'package:anime_flow/features/play/domain/play_request.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/core/video_source/domain/video_source.dart';
import 'package:anime_flow/core/video_source/application/video_source_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
export '../../application/video_source_state.dart';

part 'video_source_provider.g.dart';

@Riverpod(dependencies: [Episodes, playExtra, playSession, PlayStateNotifier])
class VideoSourceNotifier extends _$VideoSourceNotifier
    with VideoSourceWorkflow {
  @override
  VideoSourceState build() {
    ref.onDispose(disposeSearch);
    return const VideoSourceState();
  }

  @override
  bool get active => ref.mounted;

  @override
  SourceSubject get subject {
    final extra = ref.read(playExtraProvider).playExtra;
    return (
      subjectId: extra.subjectId,
      subjectName: extra.subjectName,
      subjectCover: extra.subjectCover,
      subjectAliases: extra.subjectAliases
    );
  }

  @override
  SourceEpisode get episode {
    final data = ref.read(episodesProvider).asData?.value;
    return (
      index: data?.episodeIndex ?? 0,
      sort: data?.episodeSort.toInt() ?? 0,
      id: data?.episodeId ?? 0
    );
  }

  @override
  PlaySourceRepository get sourceRepository =>
      ref.read(playSourceRepositoryProvider);

  @override
  PlayHistoryService get history => ref.read(playHistoryServiceProvider);

  @override
  IVideoSourceProvider get resolver => ref.read(playbackVideoSourceProvider);

  @override
  LocalVideoFiles get localVideoFiles => ref.read(localVideoFilesProvider);

  @override
  Future<bool> replacePlayback(
    FutureOr<PlayRequest?> Function() resolveRequest, {
    bool Function()? shouldUseResult,
  }) =>
      ref.read(playSessionProvider).replacePlayback(
            resolveRequest,
            shouldUseResult: shouldUseResult,
          );

  @override
  void setPlaybackPhase(PlaybackPhase phase,
          {PlaybackNotice notice = PlaybackNotice.none}) =>
      ref
          .read(playStateProvider.notifier)
          .setPlaybackPhase(phase, notice: notice);
}

import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/subject_episodes_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'play_content_actions.g.dart';

// Commands are read on demand and must remain alive during async selection.
@Riverpod(
  keepAlive: true,
  dependencies: [playExtra, playSession, Episodes],
)
PlayContentActions playContentActions(Ref ref) => PlayContentActions(ref);

/// Playback commands for views embedded in the active player.
class PlayContentActions {
  PlayContentActions(this.ref);
  final Ref ref;

  Future<void> resume() => ref.read(playSessionProvider).startPlaying();

  Future<void> selectEpisode(int episodeId) async {
    final extra = ref.read(playExtraProvider);
    if (!extra.isOfflineMode) {
      await ref
          .read(subjectEpisodesProvider(extra.playExtra.subjectId).notifier)
          .loadUntilEpisodeId(episodeId);
    }
    if (!ref.mounted) return;
    final current = await ref.read(episodesProvider.future);
    if (!ref.mounted) return;
    if (current.episodeId == episodeId) {
      await resume();
      return;
    }
    ref.read(episodesProvider.notifier).selectEpisode(episodeId);
  }
}

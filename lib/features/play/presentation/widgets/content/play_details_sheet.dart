import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/anime_info_view.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/features/subject_episodes/application/subject_episodes_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([
  playExtra,
  animeInfoArgs,
  AnimeInfo,
  Episodes,
  playSession,
  SubjectComments,
  SubjectStills,
  SubjectCharacters,
  SubjectProducers,
  SubjectRelated,
])
class PlayDetailsSheet extends ConsumerStatefulWidget {
  const PlayDetailsSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<PlayDetailsSheet> createState() => _PlayDetailsSheetState();
}

class _PlayDetailsSheetState extends ConsumerState<PlayDetailsSheet> {
  bool _busy = false;

  bool get _isOpen => mounted && ModalRoute.of(context)?.isActive == true;

  Future<void> _play(Future<void> Function() action) async {
    if (_busy || !_isOpen) return;
    final route = ModalRoute.of(context)!;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && route.isCurrent) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted && route.isActive) {
        NotificationToast.show(error.toString(),
            title: AppLocalizations.of(context).error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectEpisode(int episodeId) async {
    final extra = ref.read(playExtraProvider);
    if (!extra.isOfflineMode) {
      await ref
          .read(subjectEpisodesProvider(extra.playExtra.subjectId).notifier)
          .loadUntilEpisodeId(episodeId);
    }
    if (!_isOpen) return;
    final current = await ref.read(episodesProvider.future);
    if (!_isOpen) return;
    if (current.episodeId == episodeId) {
      await ref.read(playSessionProvider).startPlaying();
      return;
    }
    ref.read(episodesProvider.notifier).selectEpisode(episodeId);
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _busy,
      child: AnimeInfoView(
        scrollController: widget.scrollController,
        onPlay: () => _play(() => ref.read(playSessionProvider).startPlaying()),
        onPlayEpisode: (id) => _play(() => _selectEpisode(id)),
      ),
    );
  }
}

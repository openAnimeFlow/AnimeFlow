import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/anime_info_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Standalone detail route owns navigation to a new playback session.
class AnimeInfoPage extends ConsumerWidget {
  const AnimeInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openPlayer([int? episodeId]) {
      final subject = ref.read(animeInfoProvider).asData?.value;
      if (subject == null) return;
      final args = ref.read(animeInfoArgsProvider);
      PlayRoute.fromExtra(PlayRouteExtra(
        subjectInfo: subject,
        playExtra: PlayExtra(
          subjectId: args.id,
          subjectName: args.name,
          subjectCover: args.image,
          subjectAliases: subject.infobox
              .where((item) => item.key == '别名')
              .expand((item) => item.values.map((e) => e.v))
              .toList(),
        ),
        continueEpisodeId: episodeId,
      )).push(context);
    }

    return AnimeInfoView(onPlay: openPlayer, onPlayEpisode: openPlayer);
  }
}

import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/args/play_route_extra.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/anime_info_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

/// 详情路由负责跳转到新的播放会话。
@Dependencies([
  animeInfoArgs,
  AnimeInfo,
  SubjectComments,
  SubjectStills,
  SubjectCharacters,
  SubjectProducers,
  SubjectRelated,
])
class AnimeInfoPage extends ConsumerWidget {
  const AnimeInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    @Dependencies([AnimeInfo, animeInfoArgs])
    void openPlayer([int? episodeId]) {
      final subject = ref.read(animeInfoProvider).asData?.value;
      if (subject == null) return;
      final args = ref.read(animeInfoArgsProvider);
      appNavigatorOf(context).openPlay<void>(
          context,
          PlayRouteExtra(
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
          ));
    }

    return AnimeInfoView(onPlay: openPlayer, onPlayEpisode: openPlayer);
  }
}

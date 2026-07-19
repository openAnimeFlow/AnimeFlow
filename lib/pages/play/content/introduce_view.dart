import 'package:anime_flow/pages/play/content/recommendations.dart';
import 'package:anime_flow/pages/play/content/danmaku_card.dart';
import 'package:anime_flow/pages/play/content/episodes.dart';
import 'package:anime_flow/pages/play/content/resources.dart';
import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/widget/play_content/episode_playing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IntroduceView extends StatefulWidget {
  const IntroduceView({super.key});

  @override
  State<IntroduceView> createState() => _IntroduceViewState();
}

class _IntroduceViewState extends State<IntroduceView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Consumer(builder: (context, ref, child) {
              final subjectName = ref.watch(
                  playExtraProvider.select((e) => e.playExtra.subjectName));
              return Text(
                subjectName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              );
            }),
            const SizedBox(height: 5),
            //章节
            EpisodesComponents(
              isSelectedIcon: Consumer(
                builder: (context, ref, _) {
                  final playing = ref.watch(
                    playStateProvider.select((s) => s.playing),
                  );
                  return EpisodePlayingIndicator(
                    size: 30,
                    isPlaying: playing,
                  );
                },
              ),
            ),
            //数据源
            const VideoResourcesView(),
            //弹幕
            const DanmakuCard(),
            const RecommendationsView(),
          ],
        ),
      ),
    );
  }
}

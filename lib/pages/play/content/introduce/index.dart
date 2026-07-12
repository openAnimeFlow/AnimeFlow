import 'package:anime_flow/pages/play/content/introduce/bangumi_recommendations.dart';
import 'package:anime_flow/pages/play/content/introduce/danmaku_card.dart';
import 'package:anime_flow/pages/play/content/introduce/episodes.dart';
import 'package:anime_flow/pages/play/content/introduce/resources.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
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
            const SizedBox(height: 10),
            //章节
            const EpisodesComponents(),
            const SizedBox(height: 5),
            //数据源
            const VideoResourcesView(),
            const SizedBox(height: 5),
            //弹幕
            const DanmakuCard(),
            const SizedBox(height: 5),
            const BangumiRecommendationsView(),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

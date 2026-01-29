import 'package:anime_flow/pages/play/content/introduce/episodes.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:anime_flow/pages/play/content/introduce/danmaku_card.dart';
import 'package:anime_flow/pages/play/content/introduce/resources.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class IntroduceView extends StatefulWidget {
  const IntroduceView({super.key});

  @override
  State<IntroduceView> createState() => _IntroduceViewState();
}

class _IntroduceViewState extends State<IntroduceView>
    with AutomaticKeepAliveClientMixin {
  Logger logger = Logger();
  late PlayController playPageController;
  late PlaySubjectState playSubjectState;
  bool isVideoSourceLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    playPageController = Get.find<PlayController>();
    playSubjectState = Get.find<PlaySubjectState>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 必须调用 super.build 来启用 AutomaticKeepAliveClientMixin
    super.build(context);
    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            playSubjectState.subject.value.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
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
          // const RecommendView()
        ],
      ),
    ));
  }
}

import 'package:anime_flow/pages/play/content/introduce/episodes.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/stores/subject_state.dart';
import 'package:anime_flow/pages/play/content/introduce/danmaku_card.dart';
import 'package:anime_flow/pages/play/content/introduce/video_resources.dart';
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
  static const String drawerTitle = "章节列表";
  late PlayController playPageController;
  late SubjectState subjectStateController;
  Worker? _screenWorker; // 屏幕宽高监听器
  bool isVideoSourceLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    playPageController = Get.find<PlayController>();
    subjectStateController = Get.find<SubjectState>();
    // 初始化监听器
    _screenWorker = ever(playPageController.isWideScreen, (isWide) {
      // 如果有任何弹窗打开（BottomSheet 或 GeneralDialog），则关闭
      if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
        Get.back();
        // 延迟一点时间重新打开对应样式的弹窗
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            if (isWide) {
              EpisodesComponentsState.showSideDrawer(context);
            } else {
              EpisodesComponentsState.showBottomSheet(context);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // 清理监听器
    _screenWorker?.dispose();
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
            subjectStateController.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 10),
          //章节
          const EpisodesComponents(),
          //数据源
          const VideoResourcesView(),
          //弹幕
          const DanmakuCard(),
          const SizedBox(height: 10),
          // const RecommendView()
        ],
      ),
    ));
  }
}

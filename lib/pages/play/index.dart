import 'package:anime_flow/controllers/subject/subject_state_controller.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/webview/webview_controller.dart';
import 'package:anime_flow/widget/video/video.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/controllers/video/data/data_source_controller.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'content/index.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late SubjectBasicData subjectBasicData;
  late SubjectStateController animeStateController;
  late Future<EpisodesItem> episodes;
  late PlayController playController;
  final GlobalKey _videoKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    playController = Get.put(PlayController());
    Get.put(DataSourceController());
    Get.put(EpisodesController());
    Get.put<WebviewItemController>(
        WebviewItemControllerFactory.getController());
    var args = Get.arguments;
    subjectBasicData = args['subjectBasicData'] as SubjectBasicData;
    episodes = args['episodes'] as Future<EpisodesItem>;
    animeStateController = Get.put(SubjectStateController());
    animeStateController.setSubject(subjectBasicData.name, subjectBasicData.id);
  }

  @override
  void dispose() {
    Get.delete<WebviewItemController>();
    Get.delete<PlayController>();
    Get.delete<EpisodesController>();
    Get.delete<DataSourceController>();
    Get.delete<SubjectStateController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool isWideScreen = constraints.maxWidth > 600;
      playController.updateIsWideScreen(isWideScreen); // 更新布局状态
      return isWideScreen
          // 水平布局
          ? Scaffold(
              body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: VideoView(
                      key: _videoKey,
                    ),
                  ),
                ),
                Obx(() => AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: playController.isContentExpanded.value
                        ? PlayLayoutConstant.playContentWidth
                        : 0,
                    child: Opacity(
                      opacity: playController.isContentExpanded.value ? 1 : 0,
                      child: ContentView(
                        episodes,
                        key: _contentKey),
                    )))
              ],
            ))
          // 垂直布局
          : Scaffold(
              appBar: AppBar(
                toolbarHeight: 0,
                backgroundColor: Colors.black,
                systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
                  systemNavigationBarColor: Colors.transparent,
                ),
              ),
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: VideoView(
                        key: _videoKey),
                    ),
                    Expanded(
                      child: ContentView(
                        episodes,
                        key: _contentKey),
                    ),
                  ],
                ),
              ),
            );
    });
  }
}

import 'package:anime_flow/controllers/play/episode_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/stores/subject_state.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/webview/webview_controller.dart';
import 'package:anime_flow/widget/video/video.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/controllers/video/data/video_source_controller.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import 'content/index.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late SubjectsInfoItem subjectsInfo;
  late SubjectBasicData subjectBasicData;
  late SubjectState subjectState;
  late PlayController playController;
  late EpisodesState episodesState;
  final GlobalKey _videoKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Get.put(VideoSourceController());
    Get.put(EpisodeController());
    playController = Get.put(PlayController());
    episodesState = Get.put(EpisodesState());
    subjectState = Get.put(SubjectState());
    Get.put<WebviewItemController>(
        WebviewItemControllerFactory.getController());
    var args = Get.arguments;
    subjectsInfo = args['subjectsInfo'] as SubjectsInfoItem;
    subjectState.setSubject(
        subjectsInfo.nameCN.isEmpty ? subjectsInfo.name : subjectsInfo.nameCN,
        subjectsInfo.id,
        subjectsInfo.tags);
    _initEpisodes();
  }

  void _initEpisodes() async {
    if (episodesState.episodes.value != null) return;
    try {
      if (!episodesState.isLoading.value) {
        episodesState.isLoading.value = true;
      }
      final episodes = await BgmRequest.getSubjectEpisodesByIdService(
          subjectState.id, 100, 0);
      episodesState.episodes.value = episodes;
      episodesState.isLoading.value = false;

      if (episodesState.episodeSort.value == 0 && episodes.data.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final firstEpisode = episodes.data.first;
            episodesState.setEpisodeSort(
                sort: firstEpisode.sort,
                episodeIndex: 1,
                episodeId: firstEpisode.id);
            episodesState
                .setEpisodeTitle(firstEpisode.nameCN ?? firstEpisode.name);
          }
        });
      }
    } catch (e) {
      Logger().e(e);
      if (episodesState.isLoading.value) {
        episodesState.isLoading.value = false;
      }
    }
  }

  @override
  void dispose() {
    Get.delete<WebviewItemController>();
    Get.delete<PlayController>();
    Get.delete<EpisodesState>();
    Get.delete<VideoSourceController>();
    Get.delete<SubjectState>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool isWideScreen = constraints.maxWidth > 600;
      playController.updateIsWideScreen(isWideScreen); // 更新布局状态

      return Obx(() {
        final isFullscreen = playController.isFullscreen.value;

        // 构建内容
        Widget content;
        if (isFullscreen) {
          content = Scaffold(
            backgroundColor: Colors.black,
            body: VideoView(key: _videoKey),
          );
        } else {
          content = isWideScreen
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
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: playController.isContentExpanded.value
                            ? PlayLayoutConstant.playContentWidth
                            : 0,
                        child: Opacity(
                          opacity:
                              playController.isContentExpanded.value ? 1 : 0,
                          child: ContentView(key: _contentKey),
                        ))
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
                          child: VideoView(key: _videoKey),
                        ),
                        Expanded(
                          child: ContentView(key: _contentKey),
                        ),
                      ],
                    ),
                  ),
                );
        }

        // 手机端监听系统返回事件
        if (Utils.isMobile) {
          return PopScope(
            canPop: !isFullscreen, // 全屏时不允许返回
            onPopInvokedWithResult: (bool didPop, dynamic result) {
              if (!didPop && isFullscreen) {
                // 如果返回被阻止且当前是全屏状态，退出全屏
                playController.exitFullScreen();
              }
            },
            child: content,
          );
        }
        return content;
      });
    });
  }
}

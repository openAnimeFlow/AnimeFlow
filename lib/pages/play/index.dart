import 'package:anime_flow/controllers/play/episode_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/play/play_history.dart';
import 'package:anime_flow/repository/play_repository.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/webview/webview_controller.dart';
import 'package:anime_flow/widget/video/video.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/controllers/video/source/video_source_controller.dart';
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
  late VideoStateController videoStateController;
  late SubjectsInfoItem subjectsInfo;
  late VideoSourceController videoSourceController;
  late PlaySubjectState subjectState;
  late PlayController playController;
  late EpisodesState episodesState;
  final GlobalKey _videoKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();
  Worker? _webViewInitWorker;

  // 标记是否已经初始化过资源
  bool _hasInitResources = false;

  @override
  void initState() {
    super.initState();
    videoStateController = Get.put(VideoStateController());
    videoSourceController = Get.put(VideoSourceController());
    Get.put(EpisodeController());
    Get.put(VideoUiStateController());
    playController = Get.put(PlayController());
    episodesState = Get.put(EpisodesState());
    Get.put<WebviewItemController>(
        WebviewItemControllerFactory.getController());
    subjectState = Get.put(PlaySubjectState(Get.arguments as SubjectBasicData));
    _initEpisodes();
    _initResources();
    if(videoStateController.position.value > Duration.zero) {
      _savePlayRecord();
    }
  }

  /// 初始化资源
  void _initResources() {
    if (_hasInitResources) {
      return;
    } else {
      _webViewInitWorker =
          ever(videoSourceController.isInitWebView, (bool initialized) {
        if (initialized) {
          final subjectName = subjectState.subject.value.name;
          if (subjectName.isNotEmpty) {
            _hasInitResources = true;
            videoSourceController.initResources(subjectName);
          }
        }
      });
    }
  }

  void _initEpisodes() async {
    if (episodesState.episodes.value != null) return;
    try {
      if (!episodesState.isLoading.value) {
        episodesState.isLoading.value = true;
      }
      final episodes = await BgmRequest.getSubjectEpisodesByIdService(
          subjectState.subject.value.id, 100, 0);
      episodesState.episodes.value = episodes;
      episodesState.isLoading.value = false;

      if (episodesState.episodeSort.value == 0 && episodes.data.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // 查找第一个未看过的剧集
            int targetIndex = 0;
            for (int i = 0; i < episodes.data.length; i++) {
              if (episodes.data[i].collection == null) {
                targetIndex = i;
                break;
              }
              // 如果所有剧集都已看过，选择最后一集
              if (i == episodes.data.length - 1) {
                targetIndex = i;
              }
            }
            final targetEpisode = episodes.data[targetIndex];
            episodesState.setEpisodeSort(
                sort: targetEpisode.sort,
                episodeIndex: targetIndex + 1,
                episodeId: targetEpisode.id);
            episodesState
                .setEpisodeTitle(targetEpisode.nameCN ?? targetEpisode.name);
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

  ///保存播放记录
  void _savePlayRecord() async {
    final subjectId = subjectsInfo.id;
    final subjectName = subjectState.subject.value.name;
    final subjectImage = subjectState.subject.value.image;
    // 这里需要使用剧集索引作为剧集号,方便后续使用
    final episodeSort = episodesState.episodeIndex.value;
    final episodeId = episodesState.episodeId.value;
    final timestamp = DateTime.now();

    final playHistory = PlayHistory(
      subjectId: subjectId,
      subjectName: subjectName,
      image: subjectImage,
      episodeSort: episodeSort,
      playTime: timestamp,
      episodeId: episodeId,
    );
    Logger().i('开始保存播放记录: $playHistory');
    PlayRepository.savePlayHistory(playHistory);
  }

  @override
  void dispose() {
    _webViewInitWorker?.dispose();
    Get.delete<WebviewItemController>();
    Get.delete<VideoStateController>();
    Get.delete<PlayController>();
    Get.delete<EpisodesState>();
    Get.delete<VideoSourceController>();
    Get.delete<PlaySubjectState>();
    Get.delete<VideoUiStateController>();
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
        if (SystemUtil.isMobile) {
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

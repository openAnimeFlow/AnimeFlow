import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/controllers/shaders/shaders_controller.dart';
import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_source_controller.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/pages/play/video/video.dart';
import 'package:anime_flow/routes/model/play_route_extra.dart';
import 'package:anime_flow/pages/play/provider/episodes_provider.dart';
import 'package:anime_flow/pages/play/provider/play_subject_provider.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'content/index.dart';

class PlayPage extends StatelessWidget {
  const PlayPage({super.key, required this.extra});

  final PlayRouteExtra extra;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        playRouteExtraProvider.overrideWithValue(extra),
      ],
      child: _PlayPageView(extra: extra),
    );
  }
}

class _PlayPageView extends ConsumerStatefulWidget {
  const _PlayPageView({required this.extra});

  final PlayRouteExtra extra;

  @override
  ConsumerState<_PlayPageView> createState() => _PlayPageViewState();
}

class _PlayPageViewState extends ConsumerState<_PlayPageView> {
  late final VideoSourceController videoSourceController;
  late final PlayController playController;

  final GlobalKey _videoKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  // 标记是否已经初始化过资源
  bool _hasInitResources = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    playController = Get.put(PlayController(
      shadersController: Get.find<ShadersController>(),
    ));
    Get.put(VideoUiStateController());

    // 首帧后先重置/加载剧集，再初始化视频资源，避免集数与资源搜索不同步
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(episodesProvider.notifier).reset();
      await initEpisodes();
      if (!mounted) return;
      _initResources();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    videoSourceController = Get.put(VideoSourceController(ref.container));
  }

  @override
  void dispose() {
    Get.delete<PlayController>();
    Get.delete<VideoSourceController>();
    Get.delete<VideoUiStateController>();
    super.dispose();
  }

  /// 初始化资源
  /// TODO 不应该在这调用
  void _initResources() {
    if (_hasInitResources) {
      return;
    }

    final subjectName = ref.read(playSubjectProvider).subjectName;
    if (subjectName.isNotEmpty) {
      _hasInitResources = true;
      videoSourceController.initResources(subjectName);
    }
  }

  /// 初始化剧集
  Future<void> initEpisodes() async {
    final episodesNotifier = ref.read(episodesProvider.notifier);
    if (ref.read(episodesProvider).episodes != null) return;
    try {
      episodesNotifier.setLoading(true);
      final subject = ref.read(playSubjectProvider);
      final episodes = await FlowRequest.getSubjectEpisodesByIdService(
          subject.subjectId, 100, 0);
      episodesNotifier.setEpisodes(episodes);
      episodesNotifier.setLoading(false);
      //如果有路由传递剧集号有限根据传递的剧集设置剧集状态
      final continueEpisode = ref.read(playContinueEpisodeProvider);
      if (continueEpisode > 0 &&
          continueEpisode <= episodes.data.length) {
        final episode = episodes.data[continueEpisode - 1];
        episodesNotifier.setEpisodeSort(
          sort: episode.sort,
          episodeIndex: continueEpisode,
          episodeId: episode.id,
        );
        episodesNotifier.setEpisodeTitle(
          episode.nameCN.isEmpty ? episode.name : episode.nameCN,
        );
        return;
      }

      if (ref.read(episodesProvider).episodeSort == 0 &&
          episodes.data.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          var targetIndex = 0;
          for (var i = 0; i < episodes.data.length; i++) {
            if (episodes.data[i].collection == null) {
              targetIndex = i;
              break;
            }
            if (i == episodes.data.length - 1) {
              targetIndex = i;
            }
          }
          final targetEpisode = episodes.data[targetIndex];
          episodesNotifier.setEpisodeSort(
            sort: targetEpisode.sort,
            episodeIndex: targetIndex + 1,
            episodeId: targetEpisode.id,
          );
          episodesNotifier.setEpisodeTitle(
            targetEpisode.nameCN.isEmpty
                ? targetEpisode.name
                : targetEpisode.nameCN,
          );
        });
      }
    } catch (e) {
      LiggLogger().e(e);
      if (ref.read(episodesProvider).isLoading) {
        episodesNotifier.setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWideScreen = constraints.maxWidth > 600;
      playController.updateIsWideScreen(isWideScreen);

      return Obx(() {
        final isFullscreen = playController.isFullscreen.value;

        Widget content;
        if (isFullscreen) {
          content = Scaffold(
            backgroundColor: Colors.black,
            resizeToAvoidBottomInset: !SystemUtil.isMobile,
            body: VideoView(key: _videoKey),
          );
        } else {
          content = isWideScreen
              ? Scaffold(
                  body: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: VideoView(key: _videoKey),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: playController.isContentExpanded.value
                            ? LayoutConstant.playContentWidth
                            : 0,
                        child: Opacity(
                          opacity:
                              playController.isContentExpanded.value ? 1 : 0,
                          child: ContentView(key: _contentKey),
                        ),
                      ),
                    ],
                  ),
                )
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

        if (SystemUtil.isMobile) {
          return PopScope(
            canPop: !isFullscreen,
            onPopInvokedWithResult: (bool didPop, dynamic result) {
              if (!didPop && isFullscreen) {
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

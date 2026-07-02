import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_source_controller.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/pages/play/video/video.dart';
import 'package:anime_flow/pages/play/provider/episodes_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'content/index.dart';

class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({super.key});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageViewState();
}

class _PlayPageViewState extends ConsumerState<PlayPage> {
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
      shadersDirectory: ref.read(shadersDirectoryProvider).requireValue,
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

    final subjectName = ref.read(playExtraProvider).playExtra.subjectName;
    if (subjectName.isNotEmpty) {
      _hasInitResources = true;
      videoSourceController.initResources(subjectName);
    }
  }

  /// 初始化剧集
  Future<void> initEpisodes() async {
    final episodesNotifier = ref.read(episodesProvider.notifier);
    if (ref.read(episodesProvider).episodes != null) return;

    final subjectId = ref.read(playExtraProvider).playExtra.subjectId;
    try {
      await episodesNotifier.loadInitial(subjectId);

      final continueEpisode =
          ref.read(playExtraProvider).continueEpisode ?? 0;
      while (continueEpisode > 0 &&
          continueEpisode >
              (ref.read(episodesProvider).episodes?.data.length ?? 0) &&
          ref.read(episodesProvider).hasMore) {
        await episodesNotifier.loadMore(subjectId);
      }

      final episodes = ref.read(episodesProvider).episodes;
      if (episodes == null || episodes.data.isEmpty) {
        return;
      }

      if (continueEpisode > 0 && continueEpisode <= episodes.data.length) {
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

      if (ref.read(episodesProvider).episodeSort == 0) {
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

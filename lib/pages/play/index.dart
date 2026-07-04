import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/features/shaders/shaders_controller.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_source_controller.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/pages/play/video/video.dart';
import 'package:anime_flow/pages/play/provider/episodes_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
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

  bool _hasInitResources = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    final videoUiStateController = ref.read(videoUiStateControllerProvider.notifier);
    playController = Get.put(PlayController(
      shadersDirectory: ref.read(shadersDirectoryProvider).requireValue,
      videoUiStateActions: videoUiStateController,
    ));
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
    super.dispose();
  }

  void _initResources(String subjectName) {
    if (_hasInitResources) return;
    if (subjectName.isNotEmpty) {
      _hasInitResources = true;
      videoSourceController.initResources(subjectName);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听剧集加载完成 → 初始化视频资源搜索
    ref.listen(episodesProvider, (prev, next) {
      if (!next.isLoading && next.episodes != null) {
        final subjectName = ref.read(playExtraProvider).playExtra.subjectName;
        _initResources(subjectName);
      }
    });
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


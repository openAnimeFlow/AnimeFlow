import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/video_source_provider.dart';
import 'package:anime_flow/pages/play/video/video.dart';
import 'package:anime_flow/pages/play/providers/episodes_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content/index.dart';

class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({super.key});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageViewState();
}

class _PlayPageViewState extends ConsumerState<PlayPage> {
  late final PlaySession playSession;
  late final VideoSourceNotifier videoSourceController;

  final GlobalKey _videoKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  bool _hasInitResources = false;
  bool? _lastReportedIsWideScreen;

  @override
  void initState() {
    super.initState();
    videoSourceController = ref.read(videoSourceProvider.notifier);
    playSession = ref.read(playSessionProvider);
    videoSourceController.initVideoResources();
  }

  void _initResources(String subjectName) {
    if (_hasInitResources) return;
    if (subjectName.isNotEmpty) {
      _hasInitResources = true;
      videoSourceController.initResources(subjectName);
    }
  }

  void _syncIsWideScreenAfterBuild(bool isWideScreen) {
    if (_lastReportedIsWideScreen == isWideScreen) return;
    _lastReportedIsWideScreen = isWideScreen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      playSession.updateIsWideScreen(isWideScreen);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 监听剧集加载完成 → 初始化视频资源搜索
    ref.listen(episodesProvider, (prev, next) {
      final episodesState = next.asData?.value;
      if (episodesState?.episodes != null) {
        final subjectName = ref.read(playExtraProvider).playExtra.subjectName;
        _initResources(subjectName);
      }
    });
    return LayoutBuilder(builder: (context, constraints) {
      final isWideScreen = constraints.maxWidth > 600;
      _syncIsWideScreenAfterBuild(isWideScreen);

      final isFullscreen = ref.watch(
        playStateProvider.select((state) => state.isFullscreen),
      );
      final isContentExpanded = ref.watch(
        playStateProvider.select((state) => state.isContentExpanded),
      );

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
                      width: isContentExpanded
                          ? LayoutConstant.playContentWidth
                          : 0,
                      child: Opacity(
                        opacity: isContentExpanded ? 1 : 0,
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
              playSession.exitFullScreen();
            }
          },
          child: content,
        );
      }
      return content;
    });
  }
}

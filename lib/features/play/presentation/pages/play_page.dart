import 'dart:async';

import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/data/repository/play_repository.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/player.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/app/router/app_route_observer.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:anime_flow/shared/widgets/danmaku_text_field.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/content/comments_view.dart';
import '../widgets/content/introduce_view.dart';

class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({super.key});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage>
    with SingleTickerProviderStateMixin, RouteAware {
  late final PlaySession playSession;
  late final VideoSourceNotifier videoSourceController;
  late final AnimationController _contentAnimationController;
  late final Animation<double> _contentSizeFactor;

  final GlobalKey _videoKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  bool _hasInitResources = false;
  int? _lastOfflineEpisodeId;
  bool? _lastReportedIsWideScreen;
  bool _subscribedRouteObserver = false;
  bool _resumeWhenRouteVisible = false;

  @override
  void initState() {
    super.initState();
    videoSourceController = ref.read(videoSourceProvider.notifier);
    playSession = ref.read(playSessionProvider);
    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: ref.read(playStateProvider).isContentExpanded ? 1 : 0,
    );
    _contentSizeFactor = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (!ref.read(playExtraProvider).isOfflineMode) {
      videoSourceController.initVideoResources();
    }
  }

  @override
  void dispose() {
    if (_subscribedRouteObserver) {
      appRouteObserver.unsubscribe(this);
    }
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscribedRouteObserver) return;
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      appRouteObserver.subscribe(this, route);
      _subscribedRouteObserver = true;
    }
  }

  @override
  void didPushNext() {
    _resumeWhenRouteVisible = ref.read(playStateProvider).playing;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      playSession.pauseForRouteCover();
    });
  }

  @override
  void didPopNext() {
    if (!_resumeWhenRouteVisible) return;
    _resumeWhenRouteVisible = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      playSession.startPlaying();
    });
  }

  void _initResources(String subjectName) {
    if (ref.read(playExtraProvider).isOfflineMode) return;
    if (_hasInitResources) return;
    if (subjectName.isNotEmpty) {
      _hasInitResources = true;
      videoSourceController.initResources(subjectName);
    }
  }

  Future<void> _initOfflinePlayback(EpisodesData episodesState) async {
    final extra = ref.read(playExtraProvider);
    if (!extra.isOfflineMode) {
      return;
    }
    if (episodesState.episodes == null || episodesState.episodeIndex <= 0) {
      return;
    }
    if (_lastOfflineEpisodeId == episodesState.episodeId) {
      return;
    }
    final episode = _findOfflineEpisode(extra, episodesState);
    final mediaPath = episode?.localMediaPath.trim().isNotEmpty == true
        ? episode!.localMediaPath
        : extra.offlineMediaPath;
    if (mediaPath == null || mediaPath.isEmpty) {
      return;
    }
    _lastOfflineEpisodeId = episodesState.episodeId;

    var offset = 0;
    final history =
        await PlayRepository.getPlayHistory(extra.playExtra.subjectId);
    if (!mounted) return;
    if (history != null &&
        history.position > 0 &&
        history.episodeId == episodesState.episodeId) {
      offset = history.position;
    }

    await playSession.initPlayState(
      PlayRequest(
        videoUrl: mediaPath,
        offset: offset,
        subjectId: extra.playExtra.subjectId,
        subjectName: extra.playExtra.subjectName,
        subjectCover: extra.playExtra.subjectCover,
        episodeIndex: episodesState.episodeIndex,
        episodeSort: episodesState.episodeSort.toInt(),
        episodeId: episodesState.episodeId,
        alias: extra.playExtra.subjectAliases,
        localDanmakuPath: episode?.localDanmakuPath.trim().isNotEmpty == true
            ? episode!.localDanmakuPath
            : extra.offlineDanmakuPath,
        isLocalPlayback: true,
      ),
    );
  }

  DownloadEpisode? _findOfflineEpisode(
    PlayRouteExtra extra,
    EpisodesData episodesState,
  ) {
    final completedEpisodes = extra.offlineEpisodes
        .where((episode) => episode.status == DownloadStatus.completed)
        .where((episode) => episode.localMediaPath.trim().isNotEmpty)
        .toList()
      ..sort(_compareDownloadEpisodes);
    if (completedEpisodes.isEmpty) {
      return null;
    }
    final byId = completedEpisodes.indexWhere(
      (episode) => episode.bangumiEpisodeId == episodesState.episodeId,
    );
    if (byId >= 0) {
      return completedEpisodes[byId];
    }
    final byIndex = episodesState.episodeIndex - 1;
    if (byIndex >= 0 && byIndex < completedEpisodes.length) {
      return completedEpisodes[byIndex];
    }
    return null;
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
        final extra = ref.read(playExtraProvider);
        if (extra.isOfflineMode) {
          unawaited(_initOfflinePlayback(episodesState!));
        } else {
          _initResources(extra.playExtra.subjectName);
        }
      }
    });
    ref.listen<bool>(
      playStateProvider.select((state) => state.isContentExpanded),
      (_, isExpanded) {
        if (isExpanded) {
          _contentAnimationController.forward();
        } else {
          _contentAnimationController.reverse();
        }
      },
    );
    return LayoutBuilder(builder: (context, constraints) {
      final isWideScreen = constraints.maxWidth > 600;
      _syncIsWideScreenAfterBuild(isWideScreen);

      final isFullscreen = ref.watch(
        playStateProvider.select((state) => state.isFullscreen),
      );
      Widget content;
      if (isFullscreen) {
        content = Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: !SystemUtil.isMobile,
          body: PlayerView(key: _videoKey),
        );
      } else {
        content = isWideScreen
            ? Scaffold(
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: PlayerView(key: _videoKey),
                      ),
                    ),
                    ClipRect(
                      child: SizeTransition(
                        axis: Axis.horizontal,
                        alignment: Alignment.centerRight,
                        sizeFactor: _contentSizeFactor,
                        child: SizedBox(
                          width: LayoutConstant.playContentWidth,
                          child: _ContentView(key: _contentKey),
                        ),
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
                        child: PlayerView(key: _videoKey),
                      ),
                      Expanded(
                        child: _ContentView(key: _contentKey),
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

int _compareDownloadEpisodes(DownloadEpisode a, DownloadEpisode b) {
  final lineComparison = a.lineIndex.compareTo(b.lineIndex);
  if (lineComparison != 0) {
    return lineComparison;
  }
  final sortComparison = a.episodeSort.compareTo(b.episodeSort);
  if (sortComparison != 0) {
    return sortComparison;
  }
  return a.episodeUrl.compareTo(b.episodeUrl);
}

class _ContentView extends ConsumerStatefulWidget {
  const _ContentView({super.key});

  @override
  ConsumerState<_ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends ConsumerState<_ContentView>
    with SingleTickerProviderStateMixin {
  late final PlaySession playSession;
  late final VideoUiNotifier videoUiStateController;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    playSession = ref.read(playSessionProvider);
    videoUiStateController = ref.read(videoUiProvider.notifier);
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> onSendDanmaku(String text) async {
    final l10n = AppLocalizations.of(context);
    final userId = ref.read(currentUserInfoProvider).value?.id;
    if (userId == null) {
      NotificationToast.show(l10n.loginBeforeDanmaku, title: l10n.pleaseLogin);
      return;
    }
    final success = await playSession.sendDanmaku(
      text,
      bgmUserId: userId,
    );
    if (!mounted) return;
    NotificationToast.show(
      success ? l10n.danmakuSent : l10n.danmakuUnsupported,
      title: l10n.tip,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TabBar(
                padding:
                    EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                dividerHeight: 0,
                controller: tabController,
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                tabs: [
                  Tab(text: AppLocalizations.of(context).playIntroTab),
                  Tab(text: AppLocalizations.of(context).playCommentsTab),
                ],
              ),
              ref.watch(playStateProvider.select((state) => state.isWideScreen))
                  ? const Spacer()
                  : Consumer(
                      builder: (context, ref, _) {
                        final danmakuOn = ref.watch(
                          playStateProvider.select((state) => state.danmakuOn),
                        );
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DanmakuTextField(
                            inputVisible: danmakuOn,
                            onFocusChange: (hasFocus) {
                              if (hasFocus) {
                                playSession.stopPlaying();
                                videoUiStateController.cancelUiTimer();
                              } else {
                                playSession.startPlaying();
                                videoUiStateController.hideControlsUi();
                              }
                            },
                            onSend: (text) => onSendDanmaku(text),
                            onClose: playSession.toggleDanmaku,
                          ),
                        );
                      },
                    )
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                IntroduceView(),
                CommentsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

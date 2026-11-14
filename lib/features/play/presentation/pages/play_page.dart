import 'package:anime_flow/core/logger/app_log.dart';
import 'package:anime_flow/features/play/application/offline_playback.dart';
import 'dart:async';

import 'package:anime_flow/features/play/application/play_session.dart';
import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_state_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/player_cache_speed_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/player.dart';
import 'package:anime_flow/features/play/presentation/utils/playback_screen_awake.dart';
import 'package:anime_flow/features/user/user_api.dart';
import 'package:anime_flow/shared/navigation/app_route_observer.dart';
import 'package:anime_flow/shared/widgets/danmaku_text_field.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:anime_flow/features/play/presentation/providers/play_query_providers.dart';

import '../widgets/content/comments_view.dart';
import '../widgets/content/introduce_view.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';

@Dependencies([
  playSession,
  PlayStateNotifier,
  VideoUiNotifier,
  VideoSourceNotifier,
  Episodes,
  playExtra,
  animeInfoArgs,
  AnimeInfo,
  subjectOnlineCount,
  playerCacheSpeed,
  DanmakuStateNotifier,
  recommendation,
  SubjectComments,
  SubjectStills,
  SubjectCharacters,
  SubjectProducers,
  SubjectRelated,
  episodeComments
])
class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({super.key});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage>
    with SingleTickerProviderStateMixin, RouteAware {
  late final PlaySession playSession;
  late final PlaybackScreenAwake _screenAwake;
  late final VideoSourceNotifier videoSourceController;
  late final AnimationController _contentAnimationController;
  late final Animation<double> _contentSizeFactor;

  final GlobalKey _videoKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  bool _hasInitResources = false;
  late final OfflinePlayback _offlinePlayback;
  bool? _lastReportedIsWideScreen;
  bool _subscribedRouteObserver = false;
  bool _resumeWhenRouteVisible = false;

  @override
  void initState() {
    super.initState();
    videoSourceController =
        ref.listenManual(videoSourceProvider.notifier, (_, __) {}).read();
    playSession = ref.listenManual(playSessionProvider, (_, __) {}).read();
    _offlinePlayback = OfflinePlayback(
        ref.read(playHistoryServiceProvider), playSession.initPlayState);
    _screenAwake = PlaybackScreenAwake(playSession.playbackCoordinator.events,
        ref.read(playbackDeviceProvider).keepScreenOn);
    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: ref.read(videoUiProvider).isContentExpanded ? 1 : 0,
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
    _offlinePlayback.dispose();
    unawaited(_screenAwake.dispose());
    playSession.clearPresence();
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
    if (!extra.isOfflineMode) return;
    final file = ref
        .read(episodesProvider.notifier)
        .selection
        .offlineMediaFor(episodesState);
    try {
      await _offlinePlayback.select(
          episodes: episodesState,
          path: file?.localMediaPath ?? extra.offlineMediaPath,
          danmakuPath: file?.localDanmakuPath.trim().isNotEmpty == true
              ? file!.localDanmakuPath
              : extra.offlineDanmakuPath,
          subjectId: extra.playExtra.subjectId,
          name: extra.playExtra.subjectName,
          cover: extra.playExtra.subjectCover,
          aliases: extra.playExtra.subjectAliases);
    } catch (error, stackTrace) {
      if (!mounted) return;
      logError('本地视频打开失败', error: error, stackTrace: stackTrace);
      NotificationToast.show(AppLocalizations.of(context).openFailed);
    }
  }

  void _syncIsWideScreenAfterBuild(bool isWideScreen) {
    if (_lastReportedIsWideScreen == isWideScreen) return;
    _lastReportedIsWideScreen = isWideScreen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(videoUiProvider.notifier).setIsWideScreen(isWideScreen);
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
      videoUiProvider.select((state) => state.isContentExpanded),
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
        videoUiProvider.select((state) => state.isFullscreen),
      );
      Widget content;
      if (isFullscreen) {
        content = Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: !ref.read(playbackDeviceProvider).isMobile,
          body: Stack(
            fit: StackFit.expand,
            children: [
              PlayerView(key: _videoKey),
              Offstage(
                child: TickerMode(
                  enabled: false,
                  child: _ContentView(key: _contentKey),
                ),
              ),
            ],
          ),
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

      if (ref.read(playbackDeviceProvider).isMobile) {
        return PopScope(
          canPop: !isFullscreen,
          onPopInvokedWithResult: (bool didPop, dynamic result) {
            if (!didPop && isFullscreen) {
              ref.read(videoUiProvider.notifier).exitFullScreen();
            }
          },
          child: content,
        );
      }
      return content;
    });
  }
}

@Dependencies([
  playExtra,
  animeInfoArgs,
  playSession,
  episodeComments,
  recommendation,
  AnimeInfo,
  Episodes,
  PlayStateNotifier,
  VideoUiNotifier,
  VideoSourceNotifier,
  DanmakuStateNotifier,
  SubjectComments,
  SubjectStills,
  SubjectCharacters,
  SubjectProducers,
  SubjectRelated,
])
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

  Future<void> onSendDanmaku(String text, int type, Color color) async {
    final l10n = AppLocalizations.of(context);
    final userId = ref.read(currentUserInfoProvider).value?.id;
    if (userId == null) {
      NotificationToast.show(l10n.loginBeforeDanmaku, title: l10n.pleaseLogin);
      return;
    }
    final success = await playSession.danmaku
        .send(text, type: type, color: color.toARGB32());
    if (!mounted) return;
    NotificationToast.show(
      success ? l10n.danmakuSent : l10n.danmakuUnsupported,
      title: l10n.tip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = ref.watch(
      videoUiProvider.select((state) => state.isWideScreen),
    );
    return MediaQuery.removePadding(
      context: context,
      removeLeft: isWideScreen,
      child: SafeArea(
        left: !isWideScreen,
        bottom: false,
        child: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TabBar(
                    dividerHeight: 0,
                    controller: tabController,
                    tabAlignment: TabAlignment.start,
                    isScrollable: true,
                    tabs: [
                      Tab(text: AppLocalizations.of(context).introduction),
                      Tab(text: AppLocalizations.of(context).commentsTitle),
                    ],
                  ),
                  isWideScreen
                      ? const Spacer()
                      : Consumer(
                          builder: (context, ref, _) {
                            final danmakuOn = ref.watch(
                              danmakuStateProvider
                                  .select((state) => state.enabled),
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
                                onSend: onSendDanmaku,
                                onClose: playSession.danmaku.toggleEnabled,
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
        ),
      ),
    );
  }
}

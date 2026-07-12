import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/video_source_provider.dart';
import 'package:anime_flow/pages/play/providers/video_ui_provider.dart';
import 'package:anime_flow/pages/play/video/player.dart';
import 'package:anime_flow/pages/play/providers/episodes_provider.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/routes/app_route_observer.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/danmaku_text_field.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content/comments_view.dart';
import 'content/introduce_view.dart';

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
    videoSourceController.initVideoResources();
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


class _ContentView extends ConsumerStatefulWidget {
  const _ContentView({super.key});

  @override
  ConsumerState<_ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends ConsumerState<_ContentView>
    with SingleTickerProviderStateMixin {
  late final PlaySession playSession;
  late final VideoUiNotifier videoUiStateController;
  final List<String> tabs = ['简介', '吐槽'];
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    playSession = ref.read(playSessionProvider);
    videoUiStateController = ref.read(videoUiProvider.notifier);
    tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> onSendDanmaku(String text) async {
    final userId = ref.read(currentUserInfoProvider).value?.id;
    if (userId == null) {
      NotificationToast.show('请先登录', '请先登录后再发送弹幕');
      return;
    }
    final success = await playSession.sendDanmaku(
      text,
      bgmUserId: userId,
    );
    if (!mounted) return;
    NotificationToast.show(
      '提示',
      success ? '弹幕发送成功' : '当前不支持发送弹幕',
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
                tabs: tabs.map((name) => Tab(text: name)).toList(),
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
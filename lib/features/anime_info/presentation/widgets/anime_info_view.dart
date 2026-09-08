import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/inf_head.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_flow/features/anime_info/presentation/widgets/evaluate_dialog.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/info_appBar.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/synopsis.dart';

class AnimeInfoView extends StatefulWidget {
  const AnimeInfoView(
      {super.key, required this.onPlay, required this.onPlayEpisode});

  final VoidCallback onPlay;
  final ValueChanged<int> onPlayEpisode;

  @override
  State<AnimeInfoView> createState() => _AnimeInfoViewState();
}

class _AnimeInfoViewState extends State<AnimeInfoView> {
  final nestedScrollController = ScrollController();

  /// 内容区域的高度
  final double contentHeight = 200.0;
  bool isPinned = false;
  bool topButton = false;

  @override
  void dispose() {
    nestedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            if (notification.depth == 0) {
              final bool isPinned =
                  notification.metrics.pixels >= contentHeight;
              if (this.isPinned != isPinned) {
                setState(() {
                  this.isPinned = isPinned;
                });
              }
            }
          }
          return false;
        },
        child: NestedScrollView(
          scrollBehavior: const ScrollBehavior().copyWith(
            scrollbars: false,
          ),
          controller: nestedScrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  title: InfoAppbar(isPinned: isPinned),
                  pinned: true,
                  floating: false,
                  snap: false,
                  elevation: isPinned ? 4.0 : 0.0,
                  forceElevated: isPinned,
                  expandedHeight:
                      contentHeight + statusBarHeight + kToolbarHeight,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: InfoHeadView(
                        onPlayEpisode: widget.onPlayEpisode,
                        statusBarHeight: statusBarHeight,
                        contentHeight: contentHeight,
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: InfoSynopsisView(
            onScrollChanged: (bool showButton) {
              if (topButton != showButton) {
                setState(() {
                  topButton = showButton;
                });
              }
            },
          ),
        ),
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: Column(
          key: ValueKey<bool>(topButton),
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            if (topButton)
              FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  nestedScrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(Icons.arrow_upward_rounded,
                    color: Theme.of(context).colorScheme.primary),
              ),
            Consumer(
              builder: (context, ref, child) {
                final asyncSubjectsInfo = ref.watch(animeInfoProvider);
                return asyncSubjectsInfo.when(
                    data: (subjectsInfo) {
                      final isLoggedIn =
                          ref.watch(isLoggedInProvider).value ?? false;
                      return isLoggedIn && subjectsInfo.interest != null
                          ? FloatingActionButton(
                              heroTag: null,
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => InfoEvaluateDialog(
                                    subjectsInfo: subjectsInfo,
                                    onSaved: (updated) => ref
                                        .read(animeInfoProvider.notifier)
                                        .setAnimeInfo(updated),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.messenger,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                    error: (error, stackTrace) {
                      LiggLogger()
                          .e('获取番剧详情失败', error: error, stackTrace: stackTrace);
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink());
              },
            ),
            Consumer(builder: (context, ref, child) {
              final asyncSubjectsInfo = ref.watch(animeInfoProvider);
              final subjectsInfo = asyncSubjectsInfo.value;
              if (subjectsInfo != null) {
                return FloatingActionButton(
                  heroTag: null,
                  onPressed: widget.onPlay,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
          ],
        ),
      ),
    );
  }
}

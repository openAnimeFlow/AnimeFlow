import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/inf_head.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_flow/features/anime_info/presentation/widgets/evaluate_dialog.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/info_app_bar.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/synopsis.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([
  AnimeInfo,
  SubjectComments,
  SubjectStills,
  SubjectCharacters,
  SubjectProducers,
  SubjectRelated,
  animeInfoArgs,
])
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

  bool isPinned = false;
  bool topButton = false;

  @override
  void dispose() {
    nestedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 同一尺寸档位内复用页面；状态或组件更新时重新创建缓存，保持内容最新。
    Widget? page;
    double? previousHeight;
    double? previousTopPadding;
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentHeight = switch (constraints.maxWidth) {
          >= 1440 => 450.0,
          >= 1100 => 340.0,
          >= 840 => 260.0,
          _ => 200.0,
        };
        final topPadding = MediaQuery.paddingOf(context).top;
        if (page == null ||
            previousHeight != contentHeight ||
            previousTopPadding != topPadding) {
          previousHeight = contentHeight;
          previousTopPadding = topPadding;
          page = _buildAnimeInfoPage(context, contentHeight);
        }
        return page!;
      },
    );
  }

  Widget _buildAnimeInfoPage(BuildContext context, double contentHeight) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
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
                                    onSaved: (updated) {
                                      if (!context.mounted) return;
                                      if (ref.read(animeInfoArgsProvider).id !=
                                          updated.id) {
                                        return;
                                      }
                                      ref
                                          .read(animeInfoProvider.notifier)
                                          .setAnimeInfo(updated);
                                      ref
                                          .read(subjectCommentsProvider.notifier)
                                          .refresh();
                                    },
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

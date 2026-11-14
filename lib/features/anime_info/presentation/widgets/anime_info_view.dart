import 'package:anime_flow/shared/widgets/adaptive_sliver_app_bar.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/characters.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/details.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/info_comment.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/producers.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/related.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/tags.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/subject_stills.dart';
import 'package:anime_flow/shared/widgets/expandable_text.dart';
import 'package:shimmer/shimmer.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/inf_head.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_flow/features/anime_info/presentation/widgets/evaluate_dialog.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/info_app_bar.dart';
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
  const AnimeInfoView({
    super.key,
    required this.onPlay,
    required this.onPlayEpisode,
    this.scrollController,
  });

  final VoidCallback onPlay;
  final ValueChanged<int> onPlayEpisode;

  /// 抽屉提供滚动控制器时，使用单一滚动视图联动拖拽和内容滚动。
  final ScrollController? scrollController;

  @override
  State<AnimeInfoView> createState() => _AnimeInfoViewState();
}

class _AnimeInfoViewState extends State<AnimeInfoView> {
  final _scrollController = ScrollController();
  ScrollController get nestedScrollController =>
      widget.scrollController ?? _scrollController;
  late final _glassNavigationStyle = AppSettings.watchGlassNavigationStyle();

  bool isPinned = false;
  final _showTopButton = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _scrollController.dispose();
    _showTopButton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _glassNavigationStyle,
      initialData: AppSettings.glassNavigationStyle,
      builder: (context, snapshot) {
        final glassStyle = snapshot.data ?? false;
        // 同一尺寸档位内复用页面；状态或组件更新时重新创建缓存，保持内容最新。
        Widget? page;
        double? previousHeight;
        double? previousToolbarHeight;
        double? previousTopPadding;
        return LayoutBuilder(
          builder: (context, constraints) {
            final contentHeight = switch (constraints.maxWidth) {
              >= 1440 => 450.0,
              >= 1100 => 340.0,
              >= 840 => 260.0,
              _ => 200.0,
            };
            final toolbarHeight = switch (constraints.maxWidth) {
              >= 1440 => 72.0,
              >= 1100 => 64.0,
              >= 840 => 60.0,
              _ => kToolbarHeight,
            };
            final topPadding = MediaQuery.paddingOf(context).top;
            if (page == null ||
                previousHeight != contentHeight ||
                previousToolbarHeight != toolbarHeight ||
                previousTopPadding != topPadding) {
              previousHeight = contentHeight;
              previousToolbarHeight = toolbarHeight;
              previousTopPadding = topPadding;
              page = Scaffold(
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
                  child: widget.scrollController != null
                      ? _buildSynopsis(
                          context,
                          headerSliver: _buildSliverAppBar(context,
                              contentHeight, toolbarHeight, glassStyle),
                        )
                      : NestedScrollView(
                          scrollBehavior: const ScrollBehavior().copyWith(
                            scrollbars: false,
                          ),
                          controller: nestedScrollController,
                          headerSliverBuilder:
                              (BuildContext context, bool innerBoxIsScrolled) {
                            return <Widget>[
                              SliverOverlapAbsorber(
                                handle: NestedScrollView
                                    .sliverOverlapAbsorberHandleFor(
                                  context,
                                ),
                                sliver: _buildSliverAppBar(context,
                                    contentHeight, toolbarHeight, glassStyle),
                              ),
                            ];
                          },
                          body: _buildSynopsis(context),
                        ),
                ),
                floatingActionButton: _buildFloatingActionButton(context),
              );
            }
            return page!;
          },
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, double contentHeight,
      double toolbarHeight, bool glassStyle) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    return AdaptiveSliverAppBar(
      title: InfoAppbar(isPinned: isPinned),
      toolbarHeight: toolbarHeight,
      isPinned: isPinned,
      glassStyle: glassStyle,
      expandedHeight: contentHeight + statusBarHeight + toolbarHeight,
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
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showTopButton,
      builder: (context, showTopButton, child) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: Column(
          key: ValueKey<bool>(showTopButton),
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            if (showTopButton)
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
                final evaluateButton = asyncSubjectsInfo.when(
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
                                          .read(
                                              subjectCommentsProvider.notifier)
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
                final subjectsInfo = asyncSubjectsInfo.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    evaluateButton,
                    if (subjectsInfo != null)
                      FloatingActionButton(
                        heroTag: null,
                        onPressed: widget.onPlay,
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sliversForSubjectsInfo(
    BuildContext context,
    SubjectsInfoItem subjectsInfo, {
    required String title,
    required double fontSizeTitle,
    required FontWeight fontWeightTitle,
    required FontWeight fontWeight,
    required AppLocalizations l10n,
  }) {
    return [
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          ExpandableText(
            title: title,
            fontSizeTitle: fontSizeTitle,
            fontWeightTitle: fontWeightTitle,
            text: subjectsInfo.summary,
            fontWeight: fontWeight,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          topPadding: 25,
          TagView(
            title: l10n.tagsTitle,
            fontSizeTitle: fontSizeTitle,
            fontWeightTitle: fontWeightTitle,
            tags: subjectsInfo.tags,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            numbersSize: 10,
            numbersWeight: FontWeight.w600,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          DetailsView(
            title: l10n.detailsTitle,
            subject: subjectsInfo,
            textSize: 13,
            textFontWeight: FontWeight.w600,
          ),
          topPadding: 25,
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          const SubjectStillsView(),
          topPadding: 10,
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(context, const CharactersView(), topPadding: 10),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          const ProducersView(),
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          const RelatedView(),
        ),
      ),
      SliverToBoxAdapter(
        child: _buildContainer(
          context,
          const InfoCommentView(),
        ),
      ),
    ];
  }

  Widget _buildSynopsis(BuildContext context, {Widget? headerSliver}) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.introduction;
    const fontWeightTitle = FontWeight.bold;
    const fontSizeTitle = 20.0;
    const fontWeight = FontWeight.w600;

    return Consumer(
      builder: (context, ref, _) {
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            final metrics = scrollInfo.metrics;

            if (metrics.axis == Axis.vertical &&
                scrollInfo is ScrollUpdateNotification) {
              ref.read(subjectCommentsProvider.notifier).onCommentsScroll(
                    pixels: metrics.pixels,
                    maxScrollExtent: metrics.maxScrollExtent,
                  );

              final bool shouldShowButton = scrollInfo.metrics.pixels >= 300;

              _showTopButton.value = shouldShowButton;
            }

            return false;
          },
          child: Builder(
            builder: (BuildContext context) {
              return CustomScrollView(
                key: PageStorageKey<String>(title),
                controller:
                    headerSliver == null ? null : widget.scrollController,
                scrollBehavior: const ScrollBehavior().copyWith(
                  scrollbars: false,
                ),
                slivers: <Widget>[
                  if (headerSliver != null)
                    headerSliver
                  else
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                  Consumer(
                    builder: (context, ref, _) {
                      final subjectsInfoAsync = ref.watch(animeInfoProvider);

                      return subjectsInfoAsync.when(
                        data: (subjectsInfo) => SliverMainAxisGroup(
                          slivers: _sliversForSubjectsInfo(
                            context,
                            subjectsInfo,
                            title: title,
                            fontSizeTitle: fontSizeTitle,
                            fontWeightTitle: fontWeightTitle,
                            fontWeight: fontWeight,
                            l10n: l10n,
                          ),
                        ),
                        loading: () => _skeletonSliver(context),
                        error: (_, __) => const SliverToBoxAdapter(
                          child: SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// 构建带约束的容器
  Widget _buildContainer(
    BuildContext context,
    Widget child, {
    double topPadding = 0,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    final leftPadding = MediaQuery.of(context).padding.left;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: LayoutConstant.maxWidth,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16 + leftPadding,
            right: 16,
            top: topPadding,
          ),
          child: child,
        ),
      ),
    );
  }

  ///骨架屏
  Widget _skeletonSliver(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = Color.lerp(
      baseColor,
      isDark ? colorScheme.onSurface : colorScheme.surface,
      isDark ? 0.08 : 0.65,
    )!;
    final boxDecoration = BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(8.0),
    );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      sliver: SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: LayoutConstant.maxWidth,
            ),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 30,
                    width: 80,
                    decoration: boxDecoration,
                  ),
                  ...List.generate(6, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        height: 20,
                        width: index == 5 ? 240 : double.infinity,
                        decoration: boxDecoration,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

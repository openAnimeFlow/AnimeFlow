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
import 'package:anime_flow/shared/widgets/top_gradient_mask.dart';
import 'package:shimmer/shimmer.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/inf_head.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class AnimeInfoView extends ConsumerStatefulWidget {
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
  ConsumerState<AnimeInfoView> createState() => _AnimeInfoViewState();
}

class _AnimeInfoViewState extends ConsumerState<AnimeInfoView> {
  static final _scrollBehavior = const ScrollBehavior().copyWith(
    scrollbars: false,
    overscroll: false,
  );

  final _scrollController = ScrollController();

  ScrollController get nestedScrollController =>
      widget.scrollController ?? _scrollController;
  final _showTopButton = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _scrollController.dispose();
    _showTopButton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(animeInfoArgsProvider.select((args) => args.name));
    // 约束在同一尺寸档位内变化时复用页面。
    Widget? page;
    (double, double, double, bool)? previousLayout;
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = MediaQuery.paddingOf(context);
        final safeWidth = constraints.maxWidth - padding.horizontal;
        final compact = InfoHeadView.usesCompactLayout(safeWidth);
        final contentHeight = switch ((compact, constraints.maxWidth)) {
          (true, _) =>
            InfoHeadView.compactContentHeight(context, safeWidth, name),
          (false, >= 1440) => 450.0,
          (false, >= 1100) => 340.0,
          (false, >= 840) => 260.0,
          _ => 200.0,
        };
        final toolbarHeight = switch (constraints.maxWidth) {
          >= 1440 => 72.0,
          >= 1100 => 64.0,
          >= 840 => 60.0,
          _ => kToolbarHeight,
        };
        final statusBarHeight = padding.top;
        final layout = (contentHeight, toolbarHeight, statusBarHeight, compact);
        if (previousLayout == layout && page != null) return page!;
        previousLayout = layout;

        final header = _buildSliverAppBar(
          contentHeight: contentHeight,
          toolbarHeight: toolbarHeight,
          statusBarHeight: statusBarHeight,
          compact: compact,
        );
        page = Scaffold(
          body: widget.scrollController != null
              ? _buildSynopsis(context, headerSliver: header)
              : NestedScrollView(
                  scrollBehavior: _scrollBehavior,
                  controller: nestedScrollController,
                  headerSliverBuilder: (context, _) => [
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                      sliver: header,
                    ),
                  ],
                  body: _buildSynopsis(context),
                ),
          floatingActionButton: _buildFloatingActionButton(context),
        );
        return page!;
      },
    );
  }

  Widget _buildSliverAppBar({
    required double contentHeight,
    required double toolbarHeight,
    required double statusBarHeight,
    required bool compact,
  }) {
    const maskFadeHeight = 48.0;
    return SliverAppBar(
      title: const InfoAppbar(),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: toolbarHeight,
      pinned: true,
      backgroundColor: Colors.transparent,
      forceMaterialTransparency: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: contentHeight + toolbarHeight,
      flexibleSpace: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: InfoHeadView(
              onPlayEpisode: widget.onPlayEpisode,
              statusBarHeight: statusBarHeight,
              toolbarHeight: toolbarHeight,
              contentHeight: contentHeight,
              compact: compact,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: statusBarHeight + toolbarHeight + maskFadeHeight,
            child: IgnorePointer(
              child: Builder(
                builder: (context) {
                  final settings = context.dependOnInheritedWidgetOfExactType<
                      FlexibleSpaceBarSettings>()!;
                  final remainingHeight =
                      settings.currentExtent - settings.minExtent;
                  final opacity =
                      (1 - remainingHeight / maskFadeHeight).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity,
                    child: const TopGradientMask(),
                  );
                },
              ),
            ),
          ),
        ],
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
                final hasSubject = ref.watch(
                  animeInfoProvider.select((state) => state.hasValue),
                );
                if (!hasSubject) return const SizedBox.shrink();

                return FloatingActionButton(
                  heroTag: null,
                  onPressed: widget.onPlay,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sliversForSubjectsInfo(
    BuildContext context, {
    required String summary,
    required List<Tags> tags,
    required List<Infobox> infobox,
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
            text: summary,
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
            tags: tags,
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
            infobox: infobox,
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
                scrollBehavior: _scrollBehavior,
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
                      final subjectsInfoAsync = ref.watch(
                        animeInfoProvider.select((state) => state.whenData(
                              (subject) => (
                                summary: subject.summary,
                                tags: subject.tags,
                                infobox: subject.infobox,
                              ),
                            )),
                      );

                      return subjectsInfoAsync.when(
                        data: (subjectsInfo) => SliverMainAxisGroup(
                          slivers: _sliversForSubjectsInfo(
                            context,
                            summary: subjectsInfo.summary,
                            tags: subjectsInfo.tags,
                            infobox: subjectsInfo.infobox,
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

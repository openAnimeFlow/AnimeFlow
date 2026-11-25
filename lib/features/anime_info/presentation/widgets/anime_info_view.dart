import 'package:anime_flow/core/network/core/flow_response.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/episodes_drawer.dart';
import 'package:anime_flow/features/subject_episodes/application/subject_episodes_provider.dart';
import 'package:anime_flow/shared/models/enums/collect_type.dart';
import 'package:anime_flow/shared/navigation/args/video_resource_download_route_args.dart';
import 'package:anime_flow/shared/widgets/collection_menu.dart';
import 'package:anime_flow/shared/widgets/collection_save_notice.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/shared/navigation/args/info_route_extra.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/evaluate_form.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/characters.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/details.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/info_comment.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/producers.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/tags.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/args/image_viewer_extra.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/expandable_text.dart';
import 'package:anime_flow/shared/widgets/image_preview.dart';
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
    final layoutScale = switch ((compact, contentHeight)) {
      (false, >= 450) => 1.35,
      _ => 1.15,
    };
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
            background: Consumer(
              builder: (context, ref, _) {
                final (name, image) = ref.watch(
                  animeInfoArgsProvider
                      .select((args) => (args.name, args.image)),
                );
                final header = ref.watch(animeInfoProvider);
                final details = header.value;
                final placeholder = header.when<Widget?>(
                  data: (_) => null,
                  loading: () => _buildHeaderSkeleton(context),
                  error: (_, __) => const SizedBox.shrink(),
                );
                if (details != null && placeholder == null) {
                  // 详情页存续期间保留剧集缓存。
                  ref.watch(
                    subjectEpisodesProvider(details.id).select((_) => null),
                  );
                }
                return InfoHeadView(
                  statusBarHeight: statusBarHeight,
                  toolbarHeight: toolbarHeight,
                  contentHeight: contentHeight,
                  compact: compact,
                  name: name,
                  image: image,
                  details: details,
                  detailsPlaceholder: placeholder,
                  collectionButton: details == null || placeholder != null
                      ? null
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return Consumer(
                              builder: (context, ref, _) {
                                final isLoggedIn = ref.watch(
                                  isLoggedInProvider.select(
                                    (state) => state.value ?? false,
                                  ),
                                );
                                final collectType = isLoggedIn
                                    ? ref.watch(
                                        animeInfoProvider.select(
                                            (state) => collectTypeFromApiType(
                                                  state.value?.interest?.type,
                                                )),
                                      )
                                    : null;
                                return _buildCollectionButton(
                                  context,
                                  subjectId: details.id,
                                  collectType: collectType,
                                  layoutScale: layoutScale,
                                  isLoggedIn: isLoggedIn,
                                  onCollectionChanged: (type) =>
                                      _updateHeaderCollection(
                                    context,
                                    ref,
                                    details.id,
                                    type,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  layoutScale: layoutScale,
                  onOpenEpisodes: (subjectId) =>
                      _openHeaderEpisodes(context, ref, subjectId),
                );
              },
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

  Widget _buildHeaderSkeleton(BuildContext context) {
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
    return InfoHeadDetailsLayout(
      summary: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.only(top: 5),
              height: 20,
              width: 180,
              decoration: boxDecoration,
            );
          }),
        ),
      ),
      actions: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          height: 30,
          width: 100,
          decoration: boxDecoration,
        ),
      ),
    );
  }

  Widget _buildCollectionButton(
    BuildContext context, {
    required int subjectId,
    required CollectType? collectType,
    required double layoutScale,
    required bool isLoggedIn,
    required Future<void> Function(CollectType) onCollectionChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    if (!isLoggedIn) {
      return FilledButton.icon(
        onPressed: () => appNavigatorOf(context).goToUser(),
        style: OutlinedButton.styleFrom(
          minimumSize: Size(100 * layoutScale, 0),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: EdgeInsets.all(15 * layoutScale),
          textStyle: TextStyle(fontSize: 12 * layoutScale),
        ),
        icon: Icon(Icons.login_rounded, size: 16 * layoutScale),
        label: Text(l10n.loginToCollect),
      );
    }
    return CollectionMenu.labeled(
      key: ValueKey(subjectId),
      layoutScale: layoutScale,
      collectType: collectType,
      onCollectTypeChanged: onCollectionChanged,
    );
  }

  void _openHeaderEpisodes(
    BuildContext context,
    WidgetRef ref,
    int subjectId,
  ) {
    EpisodesDrawerView.show(
      context,
      subjectId: subjectId,
      onPlayEpisode: widget.onPlayEpisode,
      onDownloadEpisodes: (episodes) {
        appNavigatorOf(context).openVideoResourceDownload<void>(
          VideoResourceDownloadRouteArgs(
            subjectName: ref.read(animeInfoArgsProvider).name,
            subjectCover: ref.read(animeInfoArgsProvider).image,
            episodes: episodes,
          ),
        );
      },
      onEpisodeLongPress: (episode) async {
        try {
          await ref
              .read(
                subjectEpisodesProvider(subjectId).notifier,
              )
              .updateEpisodeWatched(
                episodeId: episode.id,
                watched: episode.watched != true,
              );
          if (!context.mounted) return;
          NotificationToast.show('已更新观看进度', title: '提示');
        } on AnimeFlowApiException catch (e) {
          if (!context.mounted) return;
          NotificationToast.show(e.message, title: '更新失败');
        } catch (e) {
          if (!context.mounted) return;
          NotificationToast.show(e.toString(), title: '更新失败');
        }
      },
    );
  }

  Future<void> _updateHeaderCollection(
    BuildContext context,
    WidgetRef ref,
    int subjectId,
    CollectType type,
  ) async {
    final session = ref.read(currentFlowTokenProvider).value?.sessionId;
    final previous = ref.read(animeInfoProvider).value?.interest;
    try {
      final result = await ref
          .read(animeInfoProvider.notifier)
          .updateCollectionType(type.value);
      if (!context.mounted ||
          ref.read(currentFlowTokenProvider).value?.sessionId != session ||
          ref.read(animeInfoProvider).asData?.value.id != subjectId) {
        return;
      }
      if (!type.isCollected &&
          previous != null &&
          (previous.rate > 0 || previous.comment.isNotEmpty)) {
        ref.read(subjectCommentsProvider.notifier).refresh();
      }
      showCollectionSaveNotice(context, result);
    } on AnimeFlowApiException catch (e) {
      if (context.mounted) {
        NotificationToast.show(
          e.message,
          title: '收藏更新失败',
          maxWidth: 500,
        );
      }
      rethrow;
    }
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
    required double fontSizeTitle,
    required FontWeight fontWeightTitle,
    required FontWeight fontWeight,
    required AppLocalizations l10n,
  }) {
    return [
      // 简介
      if (summary.isNotEmpty)
        SliverToBoxAdapter(
          child: _buildContainer(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                Text(
                  l10n.introduction,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: fontSizeTitle, fontWeight: fontWeightTitle),
                ),
                ExpandableText(
                  text: summary,
                  fontWeight: fontWeight,
                ),
              ],
            ),
          ),
        ),
      // 标签
      if (tags.isNotEmpty)
        SliverToBoxAdapter(
          child: _buildContainer(
            context,
            topPadding: 25,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                Text(
                  l10n.tagsTitle,
                  style: TextStyle(
                    fontSize: fontSizeTitle,
                    fontWeight: fontWeightTitle,
                  ),
                ),
                TagView(
                  tags: tags,
                ),
              ],
            ),
          ),
        ),
      // 详情
      if (infobox.isNotEmpty)
        SliverToBoxAdapter(
          child: _buildContainer(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                Text(
                  l10n.detailsTitle,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                DetailsView(
                  infobox: infobox,
                  textSize: 13,
                  textFontWeight: FontWeight.w600,
                ),
              ],
            ),
            topPadding: 25,
          ),
        ),
      // 预览图
      SliverToBoxAdapter(
        child: Consumer(
          builder: (context, ref, _) {
            final stills = ref.watch(subjectStillsProvider);
            final subjectName =
                ref.watch(animeInfoArgsProvider.select((args) => args.name));
            return stills.maybeWhen(
              data: (images) {
                if (images.isEmpty) return const SizedBox.shrink();
                final visibleImages = images.take(10).toList();
                const stillHeight = 150.0;
                return _buildContainer(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.subjectStillsTitle,
                            style: TextStyle(
                              fontSize: fontSizeTitle,
                              fontWeight: fontWeightTitle,
                            ),
                          ),
                          if (images.length > 10)
                            IconButton(
                              onPressed: () => appNavigatorOf(context)
                                  .openAnimePreview<void>(
                                images: images,
                                title: subjectName,
                              ),
                              icon: const Icon(
                                Icons.keyboard_double_arrow_right_outlined,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(
                        height: stillHeight,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: visibleImages.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final image = visibleImages[index];
                            final heroTag =
                                ImageViewer.heroTagFor(image, index);
                            return Padding(
                              padding: EdgeInsets.only(
                                  right: index == visibleImages.length - 1
                                      ? 0
                                      : 8),
                              child: GestureDetector(
                                onTap: () => appNavigatorOf(context)
                                    .openImagePreview<void>(
                                        ImageViewerRouteArgs(
                                            imageUrls: visibleImages,
                                            initialIndex: index,
                                            heroTag: heroTag)),
                                child: Hero(
                                  tag: heroTag,
                                  child: AnimationNetworkImage(
                                    gaplessResize: true,
                                    url: image,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  topPadding: 10,
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
      ),
      // 角色
      SliverToBoxAdapter(
        child: Consumer(
          builder: (context, ref, _) {
            final characters = ref.watch(subjectCharactersProvider);
            final subjectId =
                ref.watch(animeInfoArgsProvider.select((args) => args.id));
            return characters.maybeWhen(
              data: (result) {
                if (result.total <= 0) return const SizedBox.shrink();
                final detailsColor = Theme.of(context).disabledColor;
                return _buildContainer(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.charactersTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          InkWell(
                            onTap: () => appNavigatorOf(context)
                                .openCharacters<void>(subjectsId: subjectId),
                            child: Row(
                              children: [
                                Text(
                                  l10n.viewDetails,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: detailsColor,
                                  ),
                                ),
                                RotatedBox(
                                  quarterTurns: 3,
                                  child: Icon(
                                    Icons.keyboard_double_arrow_down_rounded,
                                    color: detailsColor,
                                    size: 25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      CharactersView(characters: result.data),
                    ],
                  ),
                  topPadding: 10,
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
      ),
      // 制作人
      SliverToBoxAdapter(
        child: Consumer(
          builder: (context, ref, _) =>
              ref.watch(subjectProducersProvider).maybeWhen(
                    data: (result) {
                      if (result.total <= 0) return const SizedBox.shrink();
                      return _buildContainer(
                        context,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            Text(
                              l10n.producersTitle,
                              style: TextStyle(
                                fontSize: fontSizeTitle,
                                fontWeight: fontWeightTitle,
                              ),
                            ),
                            ProducersView(producers: result.data),
                          ],
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
        ),
      ),
      // 相关条目
      SliverToBoxAdapter(
        child: Consumer(
          builder: (context, ref, _) => ref
              .watch(subjectRelatedProvider)
              .maybeWhen(
                data: (result) {
                  if (result.data.isEmpty) return const SizedBox.shrink();
                  final relations = result.data;
                  return _buildContainer(
                    context,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Text(
                          l10n.relatedTitle,
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                            fontWeight: fontWeightTitle,
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              scrollbars: false,
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: relations.length,
                              itemBuilder: (context, index) {
                                final item = relations[index];
                                const cardWidth = 100.0;
                                return Container(
                                  width: cardWidth,
                                  margin: EdgeInsets.only(
                                      right: index == relations.length - 1
                                          ? 0
                                          : 5),
                                  child: InkWell(
                                    onTap: () {
                                      appNavigatorOf(context)
                                          .openAnimeInfoFromExtra<void>(
                                              InfoRouteExtra(
                                                  id: item.subject.id,
                                                  name: item.subject.nameCN
                                                          .isEmpty
                                                      ? item.subject.name
                                                      : item.subject.nameCN,
                                                  image: item
                                                      .subject.images.large));
                                    },
                                    child: Column(
                                      children: [
                                        AnimationNetworkImage(
                                          gaplessResize: true,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          url: item.subject.images.large,
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: Text(
                                            item.subject.nameCN.isEmpty
                                                ? item.subject.name
                                                : item.subject.nameCN,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
        ),
      ),
      // 条目吐槽
      SliverToBoxAdapter(
        child: Consumer(
          builder: (context, ref, _) => ref.watch(subjectCommentsProvider).when(
                loading: () => _buildContainer(
                  context,
                  Column(
                    spacing: 8,
                    children: [
                      for (var index = 0; index < 3; index++)
                        const InfoCommentSkeleton(),
                    ],
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (viewState) {
                  final isLoggedIn =
                      ref.watch(isLoggedInProvider).value ?? false;
                  final canEvaluate = isLoggedIn &&
                      ref.watch(
                          animeInfoProvider.select((state) => state.hasValue));
                  return _buildContainer(
                    context,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.commentsTitle,
                              style: TextStyle(
                                fontSize: fontSizeTitle,
                                fontWeight: fontWeightTitle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${viewState.comments.total}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            if (canEvaluate) _buildEvaluateButton(context, ref),
                          ],
                        ),
                        InfoCommentView(
                          comments: viewState.comments.data,
                          isLoadingMore:
                              viewState.hasMore && viewState.isLoadingMore,
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ),
    ];
  }

  Widget _buildEvaluateButton(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return JellyMenu<SubjectsInfoItem?>(
      tooltip: '发表吐槽',
      triggerColor: Colors.transparent,
      barrierDismissible: false,
      keyboardAvoidance: const JellyMenuKeyboardAvoidance.adaptive(),
      trigger: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '发表吐槽',
          style: TextStyle(color: colorScheme.primary),
        ),
      ),
      menuBuilder: (context, select) {
        final subjectsInfo = ref.read(animeInfoProvider).value;
        if (subjectsInfo == null) return const SizedBox.shrink();
        return InfoEvaluateForm(
          subjectsInfo: subjectsInfo,
          onSaved: select,
          onClose: () => select(null),
        );
      },
      onSelected: (updated) {
        if (updated == null ||
            !context.mounted ||
            ref.read(animeInfoArgsProvider).id != updated.id) {
          return;
        }
        ref.read(animeInfoProvider.notifier).setAnimeInfo(updated);
        ref.read(subjectCommentsProvider.notifier).refresh();
      },
    );
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

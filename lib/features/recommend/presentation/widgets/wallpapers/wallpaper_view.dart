import 'dart:async';
import 'dart:math' as math;

import 'package:anime_flow/shared/widgets/bottom_occlusion.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/args/wallpaper_detail_args.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/features/recommend/application/wallpaper_wall.dart';
import 'package:anime_flow/features/recommend/domain/wallpaper_repository.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/recommend/presentation/widgets/wallpapers/justified_layout.dart';
import 'package:anime_flow/features/recommend/presentation/widgets/wallpapers/justified_grid.dart';
import 'package:anime_flow/features/recommend/presentation/widgets/wallpapers/wallpaper_filter_form.dart';
import 'package:anime_flow/features/recommend/presentation/widgets/wallpapers/wallpaper_skeleton.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/debounced_image_width.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:anime_flow/shared/widgets/top_occlusion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class WallpaperView extends ConsumerStatefulWidget {
  const WallpaperView({super.key, this.onOpen});

  final ValueChanged<WallpaperDetailArgs>? onOpen;

  @override
  ConsumerState<WallpaperView> createState() => _WallpaperViewState();
}

class _WallpaperViewState extends ConsumerState<WallpaperView>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _backToTopVisible = ValueNotifier(false);
  bool _scrollCheckScheduled = false;
  int _filterSession = 0;
  double _filterKeyboardAnchorHeight = 0;

  @override
  bool get wantKeepAlive => true;

  WallpaperWall get _wall => ref.read(wallpaperWallProvider.notifier);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // 首帧后再触发请求，避免在 initState 期间修改 provider 状态。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_wall.ensureLoaded());
    });
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    _loadNearBottom();
    _backToTopVisible.value = _scrollController.position.pixels > 300;
  }

  void _scheduleScrollCheck() {
    if (_scrollCheckScheduled || ref.read(wallpaperWallProvider).isLoading) {
      return;
    }
    _scrollCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCheckScheduled = false;
      if (mounted) _scrollListener();
    });
    // 尺寸通知可能在帧结束时到达，确保检查不会一直等到下一次用户操作。
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _loadNearBottom() {
    final wall = ref.read(wallpaperWallProvider);
    if (!_scrollController.hasClients || wall.failure != null) return;
    if (_scrollController.position.extentAfter < 500) {
      unawaited(_wall.loadMore());
    }
  }

  Future<void> _refresh({SortType? sort, String? keyword}) {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    return _wall.refresh(sort: sort, keyword: keyword);
  }

  void _applyFilters(WallpaperFilterResult? result) {
    if (result == null) return;
    final wall = ref.read(wallpaperWallProvider);
    if (result.sort == wall.sort && result.keyword == wall.keyword) return;
    unawaited(_refresh(sort: result.sort, keyword: result.keyword));
  }

  Widget _buildFilterMenu(WallpaperWallState wall, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return JellyMenu<WallpaperFilterResult?>(
      tooltip: l10n.filterWallpapers,
      keyboardAvoidance: JellyMenuKeyboardAvoidance.keepVisible(
        _filterKeyboardAnchorHeight,
      ),
      preferredVerticalDirection: VerticalDirection.down,
      triggerBuilder: (context, open) => InkWell(
        onTap: open,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Icon(Icons.tune, size: 18, color: theme.colorScheme.onSurface),
                Text(
                  l10n.filter,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
      onOpenChanged: (open) {
        if (open) _filterSession++;
      },
      menuBuilder: (context, select) => FocusScope(
        key: ValueKey(_filterSession),
        child: WallpaperFilterForm(
          initialKeyword: wall.keyword,
          initialSort: wall.sort,
          onKeyboardAnchorHeightChanged: (height) {
            if (_filterKeyboardAnchorHeight == height) return;
            setState(() => _filterKeyboardAnchorHeight = height);
          },
          onSubmit: select,
          onCancel: () => select(null),
        ),
      ),
      onSelected: _applyFilters,
    );
  }

  /// 失败语义已在 Data/Application 收敛，这里只决定展示哪段文案。
  String _failureMessage(WallpaperFailure failure, AppLocalizations l10n) {
    final message = failure.message?.trim();
    return message == null || message.isEmpty ? l10n.loadFailed : message;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _backToTopVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final wall = ref.watch(wallpaperWallProvider);
    ref.listen(authSessionRevisionProvider, (previous, next) {
      if (previous != null && previous != next) unawaited(_wall.refresh());
    });
    // 列表长度变化后补满视口；滚动位置与图片比例属于界面状态，留在本层。
    ref.listen<WallpaperWallState>(wallpaperWallProvider, (previous, next) {
      if (previous?.items.length != next.items.length && !next.isLoading) {
        _scheduleScrollCheck();
      }
    });
    final items = wall.items;
    return ValueListenableBuilder<bool>(
      valueListenable: _backToTopVisible,
      builder: (context, visible, child) => Scaffold(
        body: child,
        floatingActionButtonLocation:
            OcclusionAwareFabLocation(BottomOcclusionScope.of(context)),
        floatingActionButton: visible
            ? FloatingActionButton(
                heroTag: null,
                tooltip: l10n.backToTop,
                onPressed: _scrollToTop,
                child: const Icon(Icons.arrow_upward_rounded),
              )
            : null,
      ),
      // Box constraints change on resize, not on every scroll offset.
      child: LayoutBuilder(builder: (context, constraints) {
        final padding = math.max(
            12.0, (constraints.maxWidth - LayoutConstant.maxWidth) / 2);
        final topOcclusion = TopOcclusionScope.of(context);
        return NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            // 图片比例重排和窗口缩放后也要补满视口，多个通知合并检查。
            if (notification.depth == 0 &&
                notification.metrics.axis == Axis.vertical) {
              _scheduleScrollCheck();
            }
            return false;
          },
          child: RefreshIndicator(
            edgeOffset: topOcclusion,
            displacement: 10,
            onRefresh: _refresh,
            child: OcclusionAwareCustomScrollView(
              key: const PageStorageKey('wallpapers'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding:
                      EdgeInsets.symmetric(horizontal: padding, vertical: 12),
                  sliver: SliverMainAxisGroup(slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildFilterMenu(wall, l10n),
                            // 已生效的筛选条件随按钮一起展示，可单独清除。
                            if (wall.sort != SortType.trends)
                              InputChip(
                                label:
                                    Text(wallpaperSortLabel(l10n, wall.sort)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                onDeleted: () =>
                                    unawaited(_refresh(sort: SortType.trends)),
                              ),
                            if (wall.keyword.isNotEmpty)
                              InputChip(
                                avatar: const Icon(Icons.search, size: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                label: Text(wall.keyword),
                                onDeleted: () =>
                                    unawaited(_refresh(keyword: '')),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (items.isEmpty && wall.isLoading)
                      WallpaperSkeleton(
                        availableWidth: constraints.maxWidth - padding * 2,
                        rows: WallpaperSkeleton.rowsFor(
                          availableWidth: constraints.maxWidth - padding * 2,
                          viewportHeight: constraints.maxHeight,
                        ),
                      )
                    else
                      WallpaperFlow(
                        items: items,
                        onOpen: widget.onOpen,
                        availableWidth: constraints.maxWidth - padding * 2,
                        // 加载更多时把占位接在真实图片末尾，随末行一起排布。
                        skeletonCount:
                            wall.isLoading && items.isNotEmpty ? 6 : 0,
                      ),
                  ]),
                ),
                if (wall.failure != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Text(_failureMessage(wall.failure!, l10n)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => unawaited(_wall.loadMore()),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (!wall.hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child:
                            Text(items.isEmpty ? l10n.noData : l10n.rankingEnd),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// 使用实际图片比例进行两端对齐，只有最后不足一行时允许留白。
class WallpaperFlow extends StatefulWidget {
  const WallpaperFlow(
      {super.key,
      required this.items,
      required this.availableWidth,
      this.onOpen,
      this.skeletonCount = 0});

  final List<WallpaperPoster> items;
  final double availableWidth;
  final ValueChanged<WallpaperDetailArgs>? onOpen;

  /// 追加在真实图片之后的占位数量，用于「加载更多」时继续填满当前行。
  final int skeletonCount;

  @override
  State<WallpaperFlow> createState() => _WallpaperFlowState();
}

class _WallpaperFlowState extends State<WallpaperFlow> {
  final _aspectRatios = <String, double>{};
  final _pendingRatios = <String, double>{};
  Timer? _ratioUpdateTimer;
  ScrollPosition? _scrollPosition;
  Widget? _cachedSliver;
  SliverChildBuilderDelegate? _posterDelegate;

  @override
  void reassemble() {
    super.reassemble();
    _cachedSliver = null;
    _posterDelegate = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _scrollPosition) {
      _scrollPosition?.isScrollingNotifier.removeListener(_onScrollChanged);
      _scrollPosition = position;
      position?.isScrollingNotifier.addListener(_onScrollChanged);
    }
    _cachedSliver = null;
  }

  @override
  void didUpdateWidget(covariant WallpaperFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) {
      final urls = widget.items.map((item) => item.url).toSet();
      _aspectRatios.removeWhere((url, _) => !urls.contains(url));
      _pendingRatios.removeWhere((url, _) => !urls.contains(url));
      _posterDelegate = null;
      _cachedSliver = null;
    }
    if (oldWidget.availableWidth != widget.availableWidth) {
      _cachedSliver = null;
    }
    if (oldWidget.skeletonCount != widget.skeletonCount) {
      _posterDelegate = null;
      _cachedSliver = null;
    }
  }

  void _onScrollChanged() {
    if (_scrollPosition?.isScrollingNotifier.value ?? false) {
      _ratioUpdateTimer?.cancel();
      _ratioUpdateTimer = null;
    } else {
      _scheduleRatioUpdate();
    }
  }

  void _scheduleRatioUpdate() {
    if (_pendingRatios.isEmpty ||
        _ratioUpdateTimer != null ||
        (_scrollPosition?.isScrollingNotifier.value ?? false)) {
      return;
    }
    // 合并异步到达的图片尺寸，拖动和惯性滚动期间保持行位置稳定。
    _ratioUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      _ratioUpdateTimer = null;
      if (!mounted || _pendingRatios.isEmpty) return;
      setState(() {
        _aspectRatios.addAll(_pendingRatios);
        _pendingRatios.clear();
        _cachedSliver = null;
      });
    });
  }

  void _onImageSize(WallpaperPoster poster, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final ratio = size.width / size.height;
    final previous = _pendingRatios[poster.url] ??
        _aspectRatios[poster.url] ??
        poster.placeholderAspectRatio;
    // 解码取整造成的亚像素差异不值得重排整片列表。
    if (!ratio.isFinite || (previous - ratio).abs() < 0.005) {
      return;
    }
    _pendingRatios[poster.url] = ratio;
    _scheduleRatioUpdate();
  }

  @override
  void dispose() {
    _ratioUpdateTimer?.cancel();
    _scrollPosition?.isScrollingNotifier.removeListener(_onScrollChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _cachedSliver ??= _buildSliver();
  }

  Widget _buildSliver() {
    const spacing = 12.0;
    final availableWidth = widget.availableWidth;
    final targetHeight = availableWidth < 600 ? 180.0 : 220.0;
    final isCompact = availableWidth < 600;
    final items = widget.items;
    final rows = justifyImageRows(
      [
        ...items.map((poster) =>
            _aspectRatios[poster.url] ?? poster.placeholderAspectRatio),
        // 与真实图片同一次计算，占位才能填进最后一行剩余的位置。
        ...wallpaperPlaceholderRatios(widget.skeletonCount),
      ],
      availableWidth: availableWidth,
      targetHeight: targetHeight,
      spacing: spacing,
      minItemWidth: isCompact ? 120 : 0,
      minItemsPerRow: isCompact ? 2 : 1,
      maxItemsPerRow: isCompact ? 2 : null,
    );

    return SliverGrid(
      gridDelegate: JustifiedGridDelegate(JustifiedGridLayout(
        rows,
        availableWidth: availableWidth,
        spacing: spacing,
        reverseCrossAxis: Directionality.of(context) == TextDirection.rtl,
      )),
      // 宽度/图片比例变化仅更新布局，复用 builder，避免重建图片子树。
      delegate: _posterDelegate ??= _buildPosterDelegate(),
    );
  }

  SliverChildBuilderDelegate _buildPosterDelegate() {
    final items = widget.items;
    final indices = {
      for (var i = 0; i < items.length; i++) items[i].subject.subjectId: i,
    };
    return SliverChildBuilderDelegate(
      (context, index) {
        if (index >= items.length) {
          return WallpaperSkeletonTile(
            key: ValueKey('wallpaper-skeleton-$index'),
          );
        }
        final poster = items[index];
        return Padding(
          key: ValueKey(poster.subject.subjectId),
          padding: const EdgeInsets.only(bottom: 12),
          child: _PosterCard(
            poster: poster,
            onOpen: (args) {
              final open = widget.onOpen;
              if (open != null) {
                open(args);
              } else {
                unawaited(appNavigatorOf(context).openWallpaper<void>(args));
              }
            },
            onImageSize: (size) => _onImageSize(poster, size),
          ),
        );
      },
      childCount: items.length + widget.skeletonCount,
      findChildIndexCallback: (key) =>
          key is ValueKey<int> ? indices[key.value] : null,
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard(
      {required this.poster, required this.onOpen, required this.onImageSize});

  final WallpaperPoster poster;
  final ValueChanged<WallpaperDetailArgs> onOpen;
  final ValueChanged<Size> onImageSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onOpen(WallpaperDetailArgs(
        subject: poster.subject,
        initialUrl: poster.url,
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DebouncedImageWidth(
              // 保持窗口缩放和跨断点时的缩略图缓存键稳定。
              width: poster.isBackdrop ? 450 : 300,
              builder: (context, cacheWidth) => AnimationNetworkImage(
                url: poster.url,
                memCacheWidth:
                    (((cacheWidth + 127) ~/ 128) * 128).clamp(128, 1536),
                gaplessResize: true,
                fadeInDuration: const Duration(milliseconds: 150),
                fadeOutDuration: const Duration(milliseconds: 100),
                onImageSize: onImageSize,
                // 解码后行高、列宽按原图比例重算；重排前也不裁剪。
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.78)
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
                    child: Text(
                      poster.subject.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

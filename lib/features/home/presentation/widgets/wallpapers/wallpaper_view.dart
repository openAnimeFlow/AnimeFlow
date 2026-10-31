import 'dart:async';
import 'dart:math' as math;

import 'package:anime_flow/shared/widgets/bottom_occlusion.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/args/wallpaper_detail_args.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/core/network/core/flow_response.dart';
import 'package:anime_flow/features/home/presentation/providers/wallpaper_controller.dart';
import 'package:anime_flow/features/home/presentation/widgets/wallpapers/justified_layout.dart';
import 'package:anime_flow/features/home/presentation/widgets/wallpapers/justified_grid.dart';
import 'package:anime_flow/features/home/presentation/widgets/wallpapers/wallpaper_browser.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/top_occlusion.dart';
import 'package:material_ui/material_ui.dart';

class WallpaperView extends StatefulWidget {
  const WallpaperView({super.key});

  @override
  State<WallpaperView> createState() => _WallpaperViewState();
}

class _WallpaperViewState extends State<WallpaperView>
    with AutomaticKeepAliveClientMixin {
  final _controller = WallpaperController();
  final _scrollController = ScrollController();
  final _backToTopVisible = ValueNotifier(false);
  bool _scrollCheckScheduled = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _controller.addListener(_scheduleScrollCheck);
    unawaited(_controller.refresh());
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    _loadNearBottom();
    _backToTopVisible.value = _scrollController.position.pixels > 300;
  }

  void _scheduleScrollCheck() {
    if (_scrollCheckScheduled || _controller.isLoading) return;
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
    if (!_scrollController.hasClients || _controller.error != null) return;
    if (_scrollController.position.extentAfter < 500) {
      unawaited(_controller.loadMore());
    }
  }

  Future<void> _refresh({SortType? sort}) {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    return _controller.refresh(sort: sort);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _controller.removeListener(_scheduleScrollCheck);
    _controller.dispose();
    _backToTopVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    return WallpaperBrowser(
      listBuilder: (context, onOpen) => ValueListenableBuilder<bool>(
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final items = _controller.items;
            final sorts = {
              SortType.trends: l10n.sortTrends,
              SortType.collects: l10n.collection,
              SortType.rank: l10n.sortRank,
              SortType.date: l10n.sortDate,
            };
            // Box constraints change on resize, not on every scroll offset.
            return LayoutBuilder(builder: (context, constraints) {
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
                        padding: EdgeInsets.symmetric(
                            horizontal: padding, vertical: 12),
                        sliver: SliverMainAxisGroup(slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final entry in sorts.entries)
                                    ChoiceChip(
                                      label: Text(entry.value),
                                      selected: _controller.sort == entry.key,
                                      onSelected: (selected) {
                                        if (selected) {
                                          unawaited(_refresh(sort: entry.key));
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          WallpaperFlow(
                            items: items,
                            onOpen: onOpen,
                            availableWidth: constraints.maxWidth - padding * 2,
                          ),
                        ]),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: _controller.isLoading
                                ? const CircularProgressIndicator()
                                : _controller.error != null
                                    ? Column(
                                        children: [
                                          Text(resolveAnimeFlowErrorMessage(
                                            _controller.error!,
                                            fallback: l10n.collectionLoadFailed,
                                          )),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: _controller.loadMore,
                                            child: Text(l10n.retry),
                                          ),
                                        ],
                                      )
                                    : _controller.hasMore
                                        ? const SizedBox.shrink()
                                        : Text(items.isEmpty
                                            ? l10n.noData
                                            : l10n.rankingEnd),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

/// 使用实际图片比例进行两端对齐，只有最后不足一行时允许留白。
class WallpaperFlow extends StatefulWidget {
  const WallpaperFlow(
      {super.key,
      required this.items,
      required this.availableWidth,
      this.onOpen});

  final List<WallpaperPoster> items;
  final double availableWidth;
  final ValueChanged<WallpaperDetailArgs>? onOpen;

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
  double _pixelRatio = 1;

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
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    if (_pixelRatio != pixelRatio) {
      _pixelRatio = pixelRatio;
      _posterDelegate = null;
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
      items
          .map((poster) =>
              _aspectRatios[poster.url] ?? poster.placeholderAspectRatio)
          .toList(),
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
    final pixelRatio = _pixelRatio;
    return SliverChildBuilderDelegate(
      (context, index) {
        final poster = items[index];
        // 覆盖窄屏两列的常用尺寸；拖动窗口及跨越 600 断点不切换缓存键。
        final logicalWidth = poster.isBackdrop ? 450.0 : 300.0;
        final decodeWidth =
            ((logicalWidth * pixelRatio / 128).ceil() * 128).clamp(128, 1536);
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
            memCacheWidth: decodeWidth,
            onImageSize: (size) => _onImageSize(poster, size),
          ),
        );
      },
      childCount: items.length,
      findChildIndexCallback: (key) =>
          key is ValueKey<int> ? indices[key.value] : null,
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard(
      {required this.poster,
      required this.onOpen,
      required this.memCacheWidth,
      required this.onImageSize});

  final WallpaperPoster poster;
  final ValueChanged<WallpaperDetailArgs> onOpen;
  final int memCacheWidth;
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
            AnimationNetworkImage(
              url: poster.url,
              memCacheWidth: memCacheWidth,
              fadeInDuration: const Duration(milliseconds: 150),
              fadeOutDuration: const Duration(milliseconds: 100),
              onImageSize: onImageSize,
              // 解码后行高、列宽按原图比例重算；重排前也不裁剪。
              fit: BoxFit.contain,
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

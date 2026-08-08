import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/bangumi/calendar_item.dart';
import 'package:anime_flow/features/home/presentation/providers/anime_provider.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/ranking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final ScrollController _scrollController = ScrollController();
  final weekday = DateTime.now().weekday;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  /// 与常见平板/桌面分界一致：窄 / 中 / 宽 三档。
  static const double _bpMedium = 600;
  static const double _bpExpanded = 900;

  /// 骨架卡片数量
  static const int _skeletonPlaceholderCount = 6;

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canScrollLeft = position.pixels > 0.5;
    final canScrollRight = position.pixels < position.maxScrollExtent - 0.5;
    if (canScrollLeft == _canScrollLeft && canScrollRight == _canScrollRight) {
      return;
    }
    if (mounted) {
      setState(() {
        _canScrollLeft = canScrollLeft;
        _canScrollRight = canScrollRight;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (position.pixels + delta)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  double windowWidth(BuildContext context) => MediaQuery.of(context).size.width;

  double _carouselHeight(double width) {
    if (width >= _bpExpanded) return 300;
    if (width >= _bpMedium) return 250;
    return 200;
  }

  double _cardWidth(double width) {
    if (width >= _bpExpanded) return 200;
    if (width >= _bpMedium) return 170;
    return 140;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final l10n = AppLocalizations.of(context);
        final calendarAsync = ref.watch(animeCalendarProvider);

        return calendarAsync.when(
          loading: () => _buildCalendarSection(
            context,
            content: _buildCalendarSkeletonCarousel(context),
            l10n: l10n,
          ),
          error: (error, stackTrace) => _buildCalendarSection(
            context,
            content: Center(
              child: InkWell(
                onTap: () => ref
                    .read(animeCalendarProvider.notifier)
                    .refreshCalendarDate(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Text(l10n.loadFailed),
                      const Icon(Icons.refresh),
                    ],
                  ),
                ),
              ),
            ),
            l10n: l10n,
          ),
          data: (calendar) {
            final numberOfReleases =
                calendar.calendarData[weekday.toString()]?.length ?? 0;
            final numberOfViewers = calendar.calendarData[weekday.toString()]
                    ?.fold(0, (sum, item) => sum + item.subject.rating.total) ??
                0;

            return SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.todayBroadcast,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => const CalendarRoute().push(context),
                            child: Row(
                              children: [
                                Text(
                                  l10n.viewMore,
                                  style: TextStyle(
                                    fontSize:
                                        windowWidth(context) > 600 ? 15 : 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_double_arrow_right_rounded,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            l10n.calendarSummary(
                              weekday,
                              numberOfReleases,
                              numberOfViewers,
                            ),
                            style: TextStyle(
                              fontSize: windowWidth(context) > 600 ? 15 : 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: _carouselHeight(windowWidth(context)),
                    child: _buildContent(context, calendar, l10n),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarSection(BuildContext context,
      {required Widget content, required AppLocalizations l10n}) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  l10n.todayBroadcast,
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: _carouselHeight(windowWidth(context)),
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSkeletonCarousel(BuildContext context) {
    final w = windowWidth(context);
    final cardW = _cardWidth(w);
    return _buildDesktopScrollControls(
      context,
      ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: _skeletonPlaceholderCount,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            width: cardW,
            margin: EdgeInsets.only(
              right: index == _skeletonPlaceholderCount - 1 ? 0 : 10,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildCalendarPosterSkeleton(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarPosterSkeleton(BuildContext context) {
    final isDark = SystemUtil.isDarkTheme(context);
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final filler = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: Container(color: filler)),
          Positioned(
            left: 10,
            right: 10,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: filler,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 72,
                  decoration: BoxDecoration(
                    color: filler,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, Calendar calendar, AppLocalizations l10n) {
    final items = calendar.calendarData[weekday.toString()];

    if (items == null || items.isEmpty) {
      return Center(
        child: Text(l10n.noUpdatesToday),
      );
    }

    return _buildDesktopScrollControls(
      context,
      ListView.builder(
        controller: _scrollController,
        itemCount: items.length,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemBuilder: (BuildContext context, int index) {
          final itemData = items[index].subject;
          return Container(
            width: _cardWidth(windowWidth(context)),
            margin: EdgeInsets.only(right: index == items.length - 1 ? 0 : 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () {
                  AnimeInfoRoute.fromExtra(InfoRouteExtra(
                    id: itemData.id,
                    name: itemData.nameCN.isEmpty
                        ? itemData.name
                        : itemData.nameCN,
                    image: itemData.images.large,
                  )).push(context);
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimationNetworkImage(
                        url: itemData.images.large,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black38, Colors.transparent],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Text(
                            itemData.nameCN.isEmpty
                                ? itemData.name
                                : itemData.nameCN,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                    if (itemData.rating.rank > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: RankingView(ranking: itemData.rating.rank),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopScrollControls(BuildContext context, Widget child) {
    if (!SystemUtil.isDesktop) return child;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollButtons();
    });
    return Stack(
      children: [
        Positioned.fill(child: child),
        _buildScrollButton(
          alignment: Alignment.centerLeft,
          icon: Icons.chevron_left_rounded,
          enabled: _canScrollLeft,
          onPressed: () => _scrollBy(-windowWidth(context) * 0.55),
        ),
        _buildScrollButton(
          alignment: Alignment.centerRight,
          icon: Icons.chevron_right_rounded,
          enabled: _canScrollRight,
          onPressed: () => _scrollBy(windowWidth(context) * 0.55),
        ),
      ],
    );
  }

  Widget _buildScrollButton({
    required Alignment alignment,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
          shape: const CircleBorder(),
          elevation: 2,
          child: IconButton(
            onPressed: enabled ? onPressed : null,
            icon: Icon(icon),
            constraints: const BoxConstraints(
              minHeight: 50,
              minWidth: 50
            ),
          ),
        ),
      ),
    );
  }
}

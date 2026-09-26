import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:anime_flow/shared/models/bangumi/calendar_item.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/ranking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// 每日放送页面
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedYear;
  late int _selectedMonth;
  final Set<String> _excludedTags = {};

  List<String> _weekdayLabels(AppLocalizations l10n) => [
        l10n.monday,
        l10n.tuesday,
        l10n.wednesday,
        l10n.thursday,
        l10n.friday,
        l10n.saturday,
        l10n.sunday,
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    // 默认显示当前星期
    _tabController.index = DateTime.now().weekday - 1;
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = ((now.month - 1) ~/ 3) * 3 + 1;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.todayBroadcast),
        titleSpacing: 8,
        leading: Tooltip(
          message: l10n.back,
          child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          child: Consumer(
            builder: (context, ref, _) {
              final calendarAsync = ref.watch(calendarProvider(_selectedSeason));
              return calendarAsync.maybeWhen(
                data: (calendarData) =>
                    _buildTabBarSection(context, calendarData.calendar, l10n),
                orElse: () => const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final calendarAsync = ref.watch(calendarProvider(_selectedSeason));
          return calendarAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: InkWell(
                onTap: () => ref.invalidate(calendarProvider(_selectedSeason)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [
                    Text(l10n.loadFailed),
                    const Icon(Icons.refresh),
                  ],
                ),
              ),
            ),
            data: (calendarData) {
              return TabBarView(
                controller: _tabController,
                children: List.generate(7, (index) {
                  final weekday = (index + 1).toString();
                  return _buildWeekdayContent(
                    context,
                    calendarData.calendar,
                    weekday,
                    calendarData.tags,
                    l10n,
                  );
                }),
              );
            },
          );
        },
      ),
    );
  }

  CalendarSeason? get _selectedSeason {
    if (_isCurrentSeason) return null;
    return (year: _selectedYear, month: _selectedMonth);
  }

  bool get _isCurrentSeason {
    final now = DateTime.now();
    final currentSeasonMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    return _selectedYear == now.year && _selectedMonth == currentSeasonMonth;
  }

  Future<void> _showSeasonFilter(BuildContext context) async {
    final selected = await showModalBottomSheet<({int year, int month})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final isDesktop = MediaQuery.sizeOf(context).width >= 600;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: isDesktop ? 0.90 : 0.60,
          minChildSize: 0.30,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: isDesktop ? const [0.90, 0.95] : const [0.52, 0.95],
          builder: (context, scrollController) {
            final currentYear = DateTime.now().year;
            final currentMonth = DateTime.now().month;
            final currentSeasonMonth = ((currentMonth - 1) ~/ 3) * 3 + 1;
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              '放送季度',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: '关闭',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '正在查看 $_selectedYear年${_seasonLabel(_selectedMonth)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        scrollbars: false,
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 28),
                        children: [
                          for (int year = currentYear;
                              year >= currentYear - 4;
                              year--)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 22),
                              child: _buildSeasonYearSection(
                                context,
                                year: year,
                                currentYear: currentYear,
                                currentSeasonMonth: currentSeasonMonth,
                                colorScheme: colorScheme,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    final result = selected;
    if (!mounted || result == null) return;
    if (result.year == _selectedYear && result.month == _selectedMonth) {
      return;
    }
    setState(() {
      _selectedYear = result.year;
      _selectedMonth = result.month;
      _excludedTags.clear();
    });
    _tabController.index = 0;
  }

  Widget _buildSeasonYearSection(
    BuildContext context, {
    required int year,
    required int currentYear,
    required int currentSeasonMonth,
    required ColorScheme colorScheme,
  }) {
    final theme = Theme.of(context);
    const seasonMonths = [1, 4, 7, 10];
    const seasonLabels = ['冬季', '春季', '夏季', '秋季'];
    const seasonIcons = [
      AssetsPathConstants.winter,
      AssetsPathConstants.spring,
      AssetsPathConstants.summer,
      AssetsPathConstants.autumn,
    ];
    const yearColors = [
      Color(0xFF5B6F9F),
      Color(0xFF7A6AAE),
      Color(0xFF5E8F8A),
      Color(0xFFB28155),
      Color(0xFF9B6B83),
    ];
    final yearColor = yearColors[(currentYear - year) % yearColors.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 12),
          child: Text(
            '$year',
            style: theme.textTheme.titleLarge?.copyWith(
              color: yearColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: yearColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: List.generate(seasonMonths.length, (index) {
                final month = seasonMonths[index];
                final isSelected =
                    year == _selectedYear && month == _selectedMonth;
                final isFuture =
                    year == currentYear && month > currentSeasonMonth;
                return Expanded(
                  child: _buildSeasonOption(
                    context,
                    year: year,
                    month: month,
                    label: seasonLabels[index],
                    iconPath: seasonIcons[index],
                    selected: isSelected,
                    enabled: !isFuture,
                    colorScheme: colorScheme,
                    yearColor: yearColor,
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonOption(
    BuildContext context, {
    required int year,
    required int month,
    required String label,
    required String iconPath,
    required bool selected,
    required bool enabled,
    required ColorScheme colorScheme,
    required Color yearColor,
  }) {
    final foreground = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.35);
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: enabled
          ? () => Navigator.of(context).pop((year: year, month: month))
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              selected ? yearColor.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(iconPath, width: 22, height: 22),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? yearColor : foreground,
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _seasonLabel(int month) {
    return switch (month) {
      1 => '冬季',
      4 => '春季',
      7 => '夏季',
      10 => '秋季',
      _ => '$month月',
    };
  }

  String _formatAirdate(String airdate) {
    final value = airdate.trim();
    if (value.isEmpty) return '待定';

    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{2}):(\d{2}))?',
    ).firstMatch(value);
    if (match == null) return value;

    final date = '${match.group(1)}-${match.group(2)}-${match.group(3)}';
    final hour = match.group(4);
    final minute = match.group(5);
    return hour == null || minute == null ? date : '$date $hour:$minute';
  }

  bool _isVisible(CalendarItem item) =>
      !item.subject.metaTags.any((tag) => _excludedTags.contains(tag.trim()));

  Widget _buildTabBarSection(
    BuildContext context,
    Calendar calendar,
    AppLocalizations l10n,
  ) {
    final weekdayLabels = _weekdayLabels(l10n);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1800),
        child: TabBar(
          tabAlignment: TabAlignment.start,
          controller: _tabController,
          isScrollable: true,
          // dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          labelColor: colorScheme.onPrimaryContainer,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          overlayColor: WidgetStatePropertyAll(
            colorScheme.primary.withValues(alpha: 0.08),
          ),
          splashBorderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          tabs: List.generate(7, (index) {
            final weekday = (index + 1).toString();
            final items = calendar.calendarData[weekday] ?? [];
            final visibleCount = items.where(_isVisible).length;
            return SizedBox(
              width: 76,
              child: Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weekdayLabels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.releaseCount(visibleCount),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildWeekdayContent(
    BuildContext context,
    Calendar calendar,
    String weekday,
    List<String> availableTags,
    AppLocalizations l10n,
  ) {
    final items = calendar.calendarData[weekday] ?? [];
    final weekdayLabel = _weekdayLabels(l10n)[int.parse(weekday) - 1];
    final filteredItems = items.where(_isVisible).toList();

    return CustomScrollView(
      slivers: [
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final extraWidth =
                constraints.crossAxisExtent - LayoutConstant.maxWidth;
            final horizontalPadding = extraWidth > 0 ? extraWidth / 2 : 0.0;
            return SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: SliverMainAxisGroup(
                slivers: [
                  // 季度
                  SliverToBoxAdapter(
                    child: _buildSeasonBanner(context, calendar, l10n),
                  ),
                  // 标签
                  if (availableTags.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildTagFilter(
                        context,
                        availableTags,
                        l10n,
                      ),
                    ),
                  // 番剧列表
                  if (filteredItems.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            items.isEmpty
                                ? l10n.noUpdatesOnWeekday(weekdayLabel)
                                : l10n.noData,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final columnCount =
                              _getColumnCount(constraints.crossAxisExtent);
                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columnCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                mainAxisExtent: columnCount == 1 ? 184 : 214,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildCard(
                                    context,
                                    filteredItems[index],
                                    l10n,
                                  );
                                },
                                childCount: filteredItems.length,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTagFilter(
    BuildContext context,
    List<String> tags,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text('排除标签', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.all),
              selected: _excludedTags.isEmpty,
              showCheckmark: false,
              onSelected: (_) => setState(_excludedTags.clear),
            ),
            for (final tag in tags) ...[
              const SizedBox(width: 8),
              FilterChip(
                label: Text(tag),
                selected: _excludedTags.contains(tag),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _excludedTags.add(tag);
                    } else {
                      _excludedTags.remove(tag);
                    }
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonBanner(
    BuildContext context,
    Calendar calendar,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
      child: Semantics(
        button: true,
        label: '筛选季度',
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer.withValues(alpha: 0.72),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showSeasonFilter(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.72),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_selectedYear ${_seasonLabel(_selectedMonth)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${l10n.todayBroadcast} · ${l10n.releaseCount(calendar.calendarData.values.expand((items) => items).where(_isVisible).length)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (MediaQuery.sizeOf(context).width >= 600)
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: colorScheme.tertiary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static int _getColumnCount(double width) {
    if (width >= 1600) {
      return 5;
    } else if (width >= 1200) {
      return 4;
    } else if (width >= 900) {
      return 3;
    } else if (width >= 600) {
      return 2;
    }
    return 1;
  }

  Widget _buildCard(
      BuildContext context, CalendarItem item, AppLocalizations l10n) {
    final subject = item.subject;
    final theme = Theme.of(context);
    final displayName = subject.nameCN.isEmpty ? subject.name : subject.nameCN;
    final tags = subject.metaTags.take(4).toList();

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AnimeInfoRoute.fromExtra(InfoRouteExtra(
            id: subject.id,
            name: displayName,
            image: subject.images.large,
          )).push(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 104,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimationNetworkImage(
                        url: subject.images.common.isEmpty
                            ? subject.images.large
                            : subject.images.common,
                        fit: BoxFit.cover,
                      ),
                      if (subject.rating.rank > 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: RankingView(
                            ranking: subject.rating.rank,
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tags.isNotEmpty) ...[
                      _buildTagChips(context, tags),
                      const SizedBox(height: 6),
                    ],
                    const Spacer(),
                    _buildScheduleRow(context, item, l10n),
                    _buildMetricsRow(context, item, l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagChips(BuildContext context, List<String> tags) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tags.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tags[i],
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleRow(
    BuildContext context,
    CalendarItem item,
    AppLocalizations l10n,
  ) {
    final latest = item.latestEpisode;
    final next = item.nextEpisode;
    if (latest == null && next == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scheduleText = latest?.airdate.isNotEmpty == true
        ? _formatAirdate(latest!.airdate)
        : (latest != null ? l10n.episodeNumber(latest.sort) : '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latest != null)
          Row(
            children: [
              const Icon(Icons.play_arrow_rounded, size: 17),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  scheduleText.isEmpty
                      ? '正在播放 ${l10n.episodeNumber(latest.sort)}'
                      : scheduleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        if (next != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.skip_next_rounded,
                size: 17,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  next.sort > 0
                      ? '${l10n.episodeNumber(next.sort)} · ${_formatAirdate(next.airdate)}'
                      : _formatAirdate(next.airdate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMetricsRow(
    BuildContext context,
    CalendarItem item,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final subject = item.subject;
    final score = subject.rating.score;

    return Row(
      children: [
        if (score > 0) ...[
          Icon(
            Icons.star_rate_rounded,
            size: 16,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 2),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
        ],
        if (item.episodeCount > 0) ...[
          Icon(
            Icons.movie_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            l10n.episodeCount(item.episodeCount),
            style: const TextStyle(fontSize: 12),
          ),
        ],
        const Spacer(),
        Icon(
          Icons.visibility_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          '${item.watchers}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

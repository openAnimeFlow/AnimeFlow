import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/shared/models/bangumi/calendar_item.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/features/home/presentation/providers/anime_provider.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/ranking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              final calendarAsync = ref.watch(animeCalendarProvider);
              return calendarAsync.maybeWhen(
                data: (calendar) =>
                    _buildTabBarSection(context, calendar, l10n),
                orElse: () => const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final calendarAsync = ref.watch(animeCalendarProvider);
          return calendarAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: InkWell(
                onTap: () => ref
                    .read(animeCalendarProvider.notifier)
                    .refreshCalendarDate(),
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
            data: (calendar) => TabBarView(
              controller: _tabController,
              children: List.generate(7, (index) {
                final weekday = (index + 1).toString();
                return _buildWeekdayContent(context, calendar, weekday, l10n);
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBarSection(
    BuildContext context,
    Calendar calendar,
    AppLocalizations l10n,
  ) {
    final weekdayLabels = _weekdayLabels(l10n);
    return Center(
      child: Column(
        children: [
          Column(
            children: [
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1800),
                  child: TabBar(
                    tabAlignment: TabAlignment.start,
                    controller: _tabController,
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    tabs: List.generate(7, (index) {
                      final weekday = (index + 1).toString();
                      final items = calendar.calendarData[weekday] ?? [];
                      return Tab(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(weekdayLabels[index]),
                            Text(
                              l10n.releaseCount(items.length),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    }),
                  )),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWeekdayContent(
    BuildContext context,
    Calendar calendar,
    String weekday,
    AppLocalizations l10n,
  ) {
    final items = calendar.calendarData[weekday] ?? [];
    final weekdayLabel = _weekdayLabels(l10n)[int.parse(weekday) - 1];

    if (items.isEmpty) {
      return Center(
        child: Text(
          l10n.noUpdatesOnWeekday(weekdayLabel),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 统计信息
    final totalWatchers = items.fold(0, (sum, item) => sum + item.watchers);
    final ratedItems =
        items.where((item) => item.subject.rating.score > 0).toList();
    final avgScore = ratedItems.isEmpty
        ? 0.0
        : ratedItems.fold(
              0.0,
              (sum, item) => sum + item.subject.rating.score,
            ) /
            ratedItems.length;

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
                  // 统计信息
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(l10n.animeCount,
                                l10n.releaseCount(items.length)),
                            _buildStatItem(
                                l10n.totalWatchers, '$totalWatchers'),
                            if (avgScore > 0)
                              _buildStatItem(l10n.averageRating,
                                  avgScore.toStringAsFixed(1)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 番剧列表
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
                              mainAxisExtent: columnCount == 1 ? 184 : 192,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildCard(
                                  context,
                                  items[index],
                                  l10n,
                                );
                              },
                              childCount: items.length,
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
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
    BuildContext context,
    CalendarItem item,
    AppLocalizations l10n,
  ) {
    final subject = item.subject;
    final theme = Theme.of(context);
    final displayName = subject.nameCN.isEmpty ? subject.name : subject.nameCN;
    final tags = subject.metaTags.take(4).toList();

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
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
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tags.isNotEmpty) ...[
                      _buildTagChips(context, tags),
                      const SizedBox(height: 6),
                    ],
                    const Spacer(),
                    _buildScheduleRow(item, l10n),
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
    CalendarItem item,
    AppLocalizations l10n,
  ) {
    final latest = item.latestEpisode;
    final next = item.nextEpisode;
    if (latest == null && next == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latest != null)
          Text(
            latest.sort > 0
                ? '正在播放:${l10n.episodeNumber(latest.sort)}'
                : latest.airdate,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (latest != null && next != null) const SizedBox(height: 4),
        if (next != null)
          Text(
            next.sort > 0
                ? '${l10n.nextEpisode} ${l10n.episodeNumber(next.sort)} ${next.airdate}'
                : '${l10n.nextEpisode} ${next.airdate}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
          const Icon(
            Icons.star_rate_rounded,
            size: 16,
            color: Colors.amber,
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

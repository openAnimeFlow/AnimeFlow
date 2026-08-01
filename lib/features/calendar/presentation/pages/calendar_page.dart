import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/shared/models/bangumi/calendar_item.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/features/home/presentation/providers/anime_provider.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/core/utils/layout_util.dart';
import 'package:anime_flow/shared/widgets/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:anime_flow/shared/models/bangumi/subject_item.dart';
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
    final avgScore = items
            .where((item) => item.subject.rating.score > 0)
            .fold(0.0, (sum, item) => sum + item.subject.rating.score) /
        items.where((item) => item.subject.rating.score > 0).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: LayoutConstant.maxWidth),
        child: CustomScrollView(
          slivers: [
            // 统计信息
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                          l10n.animeCount, l10n.releaseCount(items.length)),
                      _buildStatItem(l10n.totalWatchers, '$totalWatchers'),
                      if (avgScore > 0)
                        _buildStatItem(
                            l10n.averageRating, avgScore.toStringAsFixed(1)),
                    ],
                  ),
                ),
              ),
            ),
            // 番剧列表
            SliverPadding(
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: LayoutUtil.getCrossAxisCount(context),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildCard(
                        items[index].subject, items[index].watchers);
                  },
                  childCount: items.length,
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildCard(Subject itemData, int watchers) {
    final subjectBasicData = InfoRouteExtra(
      id: itemData.id,
      name: itemData.nameCN.isEmpty ? itemData.name : itemData.nameCN,
      image: itemData.images.large,
    );

    return InkWell(
      onTap: () {
        AnimeInfoRoute.fromExtra(subjectBasicData).push(context);
      },
      child: SubjectCard(
        image: itemData.images.large,
        title: itemData.nameCN.isEmpty ? itemData.name : itemData.nameCN,
        rating: itemData.rating.rank,
        isCoverAnimation: false,
      ),
    );
  }
}

import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/layout_util.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/ranking.dart';
import 'package:anime_flow/widget/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';

// 每日放送页面
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late Calendar calendar;
  late TabController _tabController;

  final List<String> _weekdayLabels = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日'
  ];

  @override
  void initState() {
    super.initState();
    calendar = Get.arguments;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日放送'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          child: Center(
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
                                Text(_weekdayLabels[index]),
                                Text(
                                  '${items.length}部',
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
          )),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(7, (index) {
          final weekday = (index + 1).toString();
          return _buildWeekdayContent(weekday);
        }),
      ),
    );
  }

  Widget _buildWeekdayContent(String weekday) {
    final items = calendar.calendarData[weekday] ?? [];

    if (items.isEmpty) {
      return Center(
        child: Text(
          '${_weekdayLabels[int.parse(weekday) - 1]}无番剧更新',
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
        constraints:
            const BoxConstraints(maxWidth: PlayLayoutConstant.maxWidth),
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
                      _buildStatItem('番剧数量', '${items.length}部'),
                      _buildStatItem('总观看人数', '$totalWatchers'),
                      if (avgScore > 0)
                        _buildStatItem('平均评分', avgScore.toStringAsFixed(1)),
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
    final subjectBasicData = SubjectBasicData(
      id: itemData.id,
      name: itemData.nameCN ?? itemData.name,
      image: itemData.images.large,
    );

    return InkWell(
      onTap: () {
        Get.toNamed(RouteName.animeInfo, arguments: subjectBasicData);
      },
      child: SubjectCard(
        image: itemData.images.large,
        title: itemData.nameCN ?? itemData.name,
        rating: itemData.rating.rank,
        isCoverAnimation: false,
      ),
    );
  }
}

import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/ranking.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  Calendar? calendar;

  @override
  void initState() {
    super.initState();
    _fetchCalendar();
  }

  void _fetchCalendar() async {
    final response = await BgmRequest.calendarService();
    setState(() {
      calendar = response;
    });
  }

  final weekday = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final numberOfReleases =
        calendar?.calendarData[weekday.toString()]?.length ?? 0;
    final numberOfViewers = calendar?.calendarData[weekday.toString()]
            ?.fold(0, (sum, item) => sum + item.subject.rating.total) ??
        0;
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text(
                    "今日放送",
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (calendar != null)
                      InkWell(
                          onTap: () {
                            Get.toNamed(RouteName.calendar,
                                arguments: calendar);
                          },
                          child: const Row(
                            children: [
                              Text(
                                '查看更多',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                              Icon(
                                Icons.keyboard_double_arrow_right_rounded,
                                color: Colors.grey,
                              ),
                            ],
                          )),
                    Text(
                      '周$weekday上映$numberOfReleases部,总$numberOfViewers人收看',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (calendar == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      final items = calendar!.calendarData[weekday.toString()];

      if (items == null || items.isEmpty) {
        return const Center(
          child: Text('今日无番剧更新'),
        );
      } else {
        return ListView.builder(
          itemCount: items.length,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemBuilder: (BuildContext context, int index) {
            final itemData = items[index].subject;
            return _buildCard(itemData);
          },
        );
      }
    }
  }

  Widget _buildCard(Subject itemData) {
    final subjectBasicData = SubjectBasicData(
      id: itemData.id,
      name: itemData.nameCN ?? itemData.name,
      image: itemData.images.large,
    );
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
              onTap: () {
                Get.toNamed(RouteName.animeInfo, arguments: subjectBasicData);
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
                          colors: [
                            Colors.black38,
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(itemData.nameCN ?? itemData.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left),
                      ),
                    ),
                  ),
                  if (itemData.rating.rank > 0)
                    Positioned(
                        top: 0,
                        left: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: RankingView(
                            ranking: itemData.rating.rank,
                          ),
                        ))
                ],
              ))),
    );
  }
}

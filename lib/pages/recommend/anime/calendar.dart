import 'package:anime_flow/models/item/bangumi/calendar_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/ranking.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anime_flow/models/item/bangumi/subject_item.dart';

class CalendarView extends StatefulWidget {
  final Calendar? calendar;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const CalendarView({
    super.key,
    this.calendar,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final ScrollController _scrollController = ScrollController();
  final weekday = DateTime.now().weekday;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numberOfReleases =
        widget.calendar?.calendarData[weekday.toString()]?.length ?? 0;
    final numberOfViewers = widget.calendar?.calendarData[weekday.toString()]
            ?.fold(0, (sum, item) => sum + item.subject.rating.total) ??
        0;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  "今日放送",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.calendar != null)
                    InkWell(
                        onTap: () =>
                          Get.toNamed(RouteName.calendar,
                              arguments: widget.calendar),
                        child: const Row(
                          children: [
                            Text(
                              '查看更多',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey),
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
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: _buildContent(weekday),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(int weekday) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (widget.calendar == null) {
      return Center(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('获取数据失败'),
          if (widget.onRefresh != null)
            IconButton(
                onPressed: widget.onRefresh, icon: const Icon(Icons.refresh))
        ],
      ));
    } else {
      final items = widget.calendar!.calendarData[weekday.toString()];

      if (items == null || items.isEmpty) {
        return const Center(
          child: Text('今日无番剧更新'),
        );
      } else {
        return Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                GestureBinding.instance.pointerSignalResolver.register(event,
                    (event) {
                  final delta = (event as PointerScrollEvent).scrollDelta.dy;
                  final newOffset = (_scrollController.offset + delta).clamp(
                    _scrollController.position.minScrollExtent,
                    _scrollController.position.maxScrollExtent,
                  );
                  _scrollController.jumpTo(newOffset);
                });
              }
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: items.length,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemBuilder: (BuildContext context, int index) {
                final itemData = items[index].subject;
                return _buildCard(itemData);
              },
            ));
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

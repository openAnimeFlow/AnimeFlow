import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/calendar_item.dart';
import 'package:anime_flow/widget/image/animation_network_image.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.all(10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  "今日放送",
                  style: TextStyle(
                      fontSize: 25, fontWeight: FontWeight.bold),
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
      final weekday = DateTime.now().weekday;
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
            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimationNetworkImage(
                        url: itemData.images.large,
                        fit: BoxFit.cover,
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }
}

import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/widget/video/controls/video_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'comments.dart';
import 'introduce.dart';

class ContentView extends StatefulWidget {
  final SubjectBasicData subjectBasicData;
  final Future<EpisodesItem> episodes;

  const ContentView(this.episodes, {super.key, required this.subjectBasicData});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView>
    with SingleTickerProviderStateMixin {
  late PlayPageController playPageController;
  final List<String> _tabs = ['简介', '吐槽'];
  late TabController _tabController;
  final GlobalKey _introduceKey = GlobalKey();
  final GlobalKey _commentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    playPageController = Get.find<PlayPageController>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TabBar(
                dividerHeight: 0,
                controller: _tabController,
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                tabs: _tabs.map((name) => Tab(text: name)).toList(),
              ),
              Obx(
                () => playPageController.isWideScreen.value
                    ? const Expanded(
                        child: Spacer(),
                      )
                    : SizedBox(
                        width: 200,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DanmakuTextField(),
                        ),
                      ),
              )
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                //简介
                IntroduceView(
                  widget.episodes,
                  key: _introduceKey,
                  subjectBasicData: widget.subjectBasicData,
                ),
                //吐槽
                CommentsView(
                  key: _commentKey,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

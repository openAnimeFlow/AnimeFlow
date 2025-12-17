import 'package:anime_flow/models/item/episodes_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:flutter/material.dart';

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
  final List<String> _tabs = ['简介', '评论'];
  late TabController _tabController;
  final GlobalKey _introduceKey = GlobalKey();
  final GlobalKey _commentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
          TabBar(
            controller: _tabController,
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            tabs: _tabs.map((name) => Tab(text: name)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                //简介view
                IntroduceView(
                  widget.episodes,
                  key: _introduceKey,
                  subjectBasicData: widget.subjectBasicData,
                ),
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

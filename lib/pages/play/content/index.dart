import 'package:anime_flow/controllers/crawler/crawler_config_controller.dart';
import 'package:anime_flow/controllers/video/data/data_source.dart';
import 'package:anime_flow/models/item/episodes_item.dart';
import 'package:anime_flow/models/item/hot_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'comments.dart';
import 'introduce.dart';

class ContentView extends StatefulWidget {
  final Subject subject;
  final Future<EpisodesItem> episodes;

  const ContentView(this.subject, this.episodes, {super.key});

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
    Get.put(CrawlerConfigController());
    Get.put(DataSource());
  }

  @override
  void dispose() {
    Get.delete<CrawlerConfigController>();
    Get.delete<DataSource>();
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
                  widget.subject,
                  widget.episodes,
                  key: _introduceKey,
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

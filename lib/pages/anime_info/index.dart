import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/pages/anime_info/info_head.dart';
import 'package:anime_flow/controllers/anime/anime_state_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'info_appBar.dart';
import 'info_synopsis.dart';

class AnimeDetailPage extends StatefulWidget {
  const AnimeDetailPage({super.key});

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  late SubjectBasicData subjectBasicData;
  late AnimeStateController animeStateController;
  late Future<SubjectsItem?> _subjectsItem;
  late Future<EpisodesItem> episodesFuture;
  final double _contentHeight = 200.0; // 内容区域的高度
  bool isPinned = false;
  bool topButton = false;
  final _nestedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    subjectBasicData = Get.arguments;
    animeStateController = Get.put(AnimeStateController());
    _subjectsItem = BgmRequest.getSubjectByIdService(subjectBasicData.id);
    episodesFuture =
        BgmRequest.getSubjectEpisodesByIdService(subjectBasicData.id, 100, 0);
    setSubjectName();
  }

  void setSubjectName() {
    animeStateController.setAnimeName(subjectBasicData.name);
  }

  @override
  void dispose() {
    _nestedScrollController.dispose();
    Get.delete<AnimeStateController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 状态栏高度
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                if (notification.depth == 0) {
                  final bool isPinned =
                      notification.metrics.pixels >= _contentHeight;
                  if (this.isPinned != isPinned) {
                    setState(() {
                      this.isPinned = isPinned;
                    });
                  }
                }
              }
              return false;
            },
            child: NestedScrollView(
              controller: _nestedScrollController,
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                    sliver: SliverAppBar(
                      automaticallyImplyLeading: false,
                      titleSpacing: 0,
                      title: FutureBuilder<SubjectsItem?>(
                        future: _subjectsItem,
                        builder: (context, snapshot) {
                          return InfoAppbarView(
                              subjectBasicData: subjectBasicData,
                              subjectsItem: snapshot.data,
                              isPinned: isPinned);
                        },
                      ),
                      pinned: true,
                      floating: false,
                      snap: false,
                      // 动态设置背景色
                      elevation: isPinned ? 4.0 : 0.0,
                      forceElevated: isPinned,

                      // 展开高度计算：内容高度 + 状态栏 + Toolbar
                      expandedHeight:
                          _contentHeight + statusBarHeight + kToolbarHeight,

                      /// 头部内容区域
                      flexibleSpace: FlexibleSpaceBar(
                          collapseMode: CollapseMode.pin,
                          background: Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: FutureBuilder<SubjectsItem?>(
                                future: _subjectsItem,
                                builder: (context, snapshot) {
                                  return InfoHeadView(
                                    subjectItem: snapshot.data,
                                    episodesItem: episodesFuture,
                                    statusBarHeight: statusBarHeight,
                                    contentHeight: _contentHeight,
                                    subjectBasicData: subjectBasicData,
                                  );
                                },
                              ))),
                    ),
                  ),
                ];
              },
              body: InfoSynopsisView(
                subjectsItem: _subjectsItem,
                onScrollChanged: (bool showButton) {
                  if (topButton != showButton) {
                    setState(() {
                      topButton = showButton;
                    });
                  }
                },
              ),
            ),
          ),
          if (topButton)
            Positioned(
              right: 10,
              bottom: 10,
              child: FloatingActionButton(
                onPressed: () {
                  _nestedScrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Icon(Icons.arrow_upward_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

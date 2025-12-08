import 'package:anime_flow/components/anime_head_detail/head_detail.dart';
import 'package:anime_flow/components/image/animation_network_image.dart';
import 'package:anime_flow/controllers/anime/anime_state_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/episodes_item.dart';
import 'package:anime_flow/models/item/hot_item.dart';
import 'package:anime_flow/models/item/subjects_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimeDetailPage extends StatefulWidget {
  const AnimeDetailPage({super.key});

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage>
    with SingleTickerProviderStateMixin {
  late Subject subject;
  late TabController tabController;
  late AnimeStateController animeStateController;
  late Future<SubjectsItem?> _subjectsItem;
  late Future<EpisodesItem> episodesFuture;

  final List<String> _tabs = ['章节', '简介', '评论'];
  final double _contentHeight = 200.0; // 内容区域的高度
  bool isPinned = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: _tabs.length, vsync: this);
    subject = Get.arguments;
    animeStateController = Get.put(AnimeStateController());
    _subjectsItem = BgmRequest.getSubjectByIdService(subject.id);
    episodesFuture =
        BgmRequest.getSubjectEpisodesByIdService(subject.id, 100, 0);

    setSubjectName();
  }

  void setSubjectName() {
    animeStateController.setAnimeName(subject.nameCN ?? subject.name);
  }

  @override
  void dispose() {
    tabController.dispose();
    Get.delete<AnimeStateController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 状态栏高度
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    // TabBar高度 (标准高度)
    const double tabBarHeight = 46.0;

    return Scaffold(
      // 让 Body 内容延伸到 AppBar 后方
      extendBodyBehindAppBar: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification is ScrollUpdateNotification) {
            final bool isPinned = notification.metrics.pixels >= _contentHeight;
            if (this.isPinned != isPinned) {
              setState(() {
                this.isPinned = isPinned;
              });
            }
          }
          return false;
        },
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  title: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.all(0),
                        iconSize: 25,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () {
                          Get.back();
                        },
                      ),
                      AnimatedOpacity(
                          opacity: isPinned ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: AnimationNetworkImage(
                                    width: 25,
                                    height: 25,
                                    fit: BoxFit.cover,
                                    url: subject.images.common),
                              ),
                              SizedBox(width: 5),
                              Text(
                                subject.nameCN ?? subject.name,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          )),
                    ],
                  ),
                  pinned: true,
                  floating: false,
                  snap: false,
                  // 动态设置背景色
                  elevation: isPinned ? 4.0 : 0.0,
                  forceElevated: isPinned,

                  // 展开高度计算：内容高度 + 状态栏 + Toolbar + TabBar
                  // 这样确保内容区域有足够的空间展示，且不会被 TabBar 遮挡太多
                  expandedHeight: _contentHeight +
                      statusBarHeight +
                      kToolbarHeight +
                      tabBarHeight,

                  /// 头部内容区域
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Container(
                      padding: EdgeInsets.only(
                        bottom: tabBarHeight, // 底部留出 TabBar 的空间
                      ),
                      // 数据内容
                      child: FutureBuilder<SubjectsItem?>(
                        future: _subjectsItem,
                        builder: (context, snapshot) {
                          return HeadDetail(
                            subject,
                            snapshot.data,
                            episodesFuture,
                            statusBarHeight: statusBarHeight,
                            contentHeight: _contentHeight,
                          );
                        },
                      ),
                    ),
                  ),

                  /// TabBar
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(tabBarHeight),
                    child: TabBar(
                      controller: tabController,
                      tabs: _tabs.map((name) => Tab(text: name)).toList(),
                    ),
                  ),
                ),
              ),
            ];
          },
          // Body 使用 TabBarView
          body: TabBarView(
            controller: tabController,
            children: _tabs.map((name) {
              return Builder(
                builder: (BuildContext context) {
                  return CustomScrollView(
                    key: PageStorageKey<String>(name),
                    slivers: <Widget>[
                      // 注入重叠区域，防止内容被 Header 遮挡
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context,
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((
                          BuildContext context,
                          int index,
                        ) {
                          return ListTile(title: Text('$name 内容 $index'));
                        }, childCount: 50),
                      ),
                    ],
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

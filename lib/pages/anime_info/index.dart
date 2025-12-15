import 'package:anime_flow/models/item/subject_comments_item.dart';
import 'package:anime_flow/pages/anime_info/info_head.dart';
import 'package:anime_flow/controllers/anime/anime_state_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/episodes_item.dart';
import 'package:anime_flow/models/item/hot_item.dart';
import 'package:anime_flow/models/item/subjects_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'info_appBar.dart';
import 'info_synopsis.dart';

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
  SubjectCommentItem? subjectCommentItem;
  final List<String> _tabs = ['简介', '评论', '论坛'];
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
    _getSubjectComment();
    setSubjectName();
  }

  void setSubjectName() {
    animeStateController.setAnimeName(subject.nameCN ?? subject.name);
  }

  void _getSubjectComment() async {
    final result = await BgmRequest.getSubjectCommentsByIdService(
        subjectId: subject.id, limit: 20, offset: 0);
    if (mounted) {
      setState(() {
        subjectCommentItem = result;
      });
    }
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
                  title: FutureBuilder<SubjectsItem?>(
                    future: _subjectsItem,
                    builder: (context, snapshot) {
                      return snapshot.data != null
                          ? InfoAppbarView(
                              subject: subject,
                              subjectsItem: snapshot.data!,
                              isPinned: isPinned,
                            )
                          : const SizedBox.shrink();
                    },
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
                      padding: const EdgeInsets.only(
                        bottom: tabBarHeight, // 底部留出 TabBar 的空间
                      ),
                      // 数据内容
                      child: FutureBuilder<SubjectsItem?>(
                        future: _subjectsItem,
                        builder: (context, snapshot) {
                          return InfoHeadView(
                            subject: subject,
                            subjectItem: snapshot.data,
                            episodesItem: episodesFuture,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabBar(
                          controller: tabController,
                          tabs: _tabs.map((name) => Tab(text: name)).toList(),
                          tabAlignment: TabAlignment.center,
                          dividerColor: Colors.transparent,
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          // Body 使用 TabBarView
          body: TabBarView(
            controller: tabController,
            children: [
              InfoSynopsisView(
                subjectsItem: _subjectsItem,
                subjectCommentItem: subjectCommentItem,
              ),
              _CommentsPage(subject: subject),
              _ForumPage(subject: subject),
            ],
          ),
        ),
      ),
    );
  }
}

/// 隐藏滚动条的ScrollBehavior
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

/// 评论页面
class _CommentsPage extends StatelessWidget {
  final Subject subject;

  const _CommentsPage({
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return ScrollConfiguration(
          behavior: _NoScrollbarBehavior(),
          child: CustomScrollView(
            key: const PageStorageKey<String>('评论'),
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
                  return ListTile(title: Text('评论 内容 $index'));
                }, childCount: 50),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 论坛页面
class _ForumPage extends StatelessWidget {
  final Subject subject;

  const _ForumPage({
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return ScrollConfiguration(
          behavior: _NoScrollbarBehavior(),
          child: CustomScrollView(
            key: const PageStorageKey<String>('论坛'),
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
                  return ListTile(title: Text('论坛 内容 $index'));
                }, childCount: 50),
              ),
            ],
          ),
        );
      },
    );
  }
}

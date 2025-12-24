import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_comments_item.dart';
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

class _AnimeDetailPageState extends State<AnimeDetailPage>
    with SingleTickerProviderStateMixin {
  late SubjectBasicData subjectBasicData;
  late AnimeStateController animeStateController;
  late Future<SubjectsItem?> _subjectsItem;
  late Future<EpisodesItem> episodesFuture;
  SubjectCommentItem? subjectCommentItem;
  int _commentOffset = 0;
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;
  final double _contentHeight = 200.0; // 内容区域的高度
  bool isPinned = false;

  @override
  void initState() {
    super.initState();
    subjectBasicData = Get.arguments;
    animeStateController = Get.put(AnimeStateController());
    _subjectsItem = BgmRequest.getSubjectByIdService(subjectBasicData.id);
    episodesFuture =
        BgmRequest.getSubjectEpisodesByIdService(subjectBasicData.id, 100, 0);
    _getSubjectComment();
    setSubjectName();
  }

  void setSubjectName() {
    animeStateController.setAnimeName(subjectBasicData.name);
  }

  void _getSubjectComment({bool loadMore = false}) async {
    if (_isLoadingComments || (loadMore && !_hasMoreComments)) return;

    setState(() {
      _isLoadingComments = true;
    });

    final currentOffset = loadMore ? _commentOffset + 1 : 0;
    final result = await BgmRequest.getSubjectCommentsByIdService(
        subjectId: subjectBasicData.id, limit: 20, offset: currentOffset);

    if (mounted) {
      setState(() {
        if (loadMore && subjectCommentItem != null) {
          // 追加数据
          final newDataList = [
            ...subjectCommentItem!.data,
            ...result.data,
          ];
          subjectCommentItem = SubjectCommentItem(
            data: newDataList,
            total: result.total,
          );
        } else {
          // 首次加载，替换数据
          subjectCommentItem = result;
        }
        _commentOffset = currentOffset;
        _hasMoreComments = result.data.isNotEmpty &&
            (subjectCommentItem?.data.length ?? 0) < (result.total);
        _isLoadingComments = false;
      });
    }
  }

  @override
  void dispose() {
    Get.delete<AnimeStateController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 状态栏高度
    final double statusBarHeight = MediaQuery.of(context).padding.top;

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
                      return  InfoAppbarView(
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
            subjectCommentItem: subjectCommentItem,
            onLoadMoreComments: () => _getSubjectComment(loadMore: true),
            isLoadingComments: _isLoadingComments,
            hasMoreComments: _hasMoreComments,
          ),
        ),
      ),
    );
  }
}

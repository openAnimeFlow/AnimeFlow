import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/pages/anime_info/evaluate_dialog.dart';
import 'package:anime_flow/pages/anime_info/head.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/stores/anime_info_store.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'appBar.dart';
import 'synopsis.dart';

class AnimeDetailPage extends StatefulWidget {
  const AnimeDetailPage({super.key});

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  late SubjectBasicData subjectBasicData;
  late UserInfoStore userInfoStore;
  late AnimeInfoStore animeInfoStore;
  SubjectsInfoItem? subjectsInfo;
  final double _contentHeight = 200.0; // 内容区域的高度
  bool isPinned = false;
  bool topButton = false;
  final _nestedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    subjectBasicData = Get.arguments;
    _getSubjects();
    userInfoStore = Get.find<UserInfoStore>();
    animeInfoStore = Get.put(AnimeInfoStore());
  }

  void _getSubjects() async {
    final response =
        await BgmRequest.getSubjectByIdService(subjectBasicData.id);
    setState(() {
      animeInfoStore.setAnimeInfo(response);
      subjectsInfo = response;
    });
  }

  @override
  void dispose() {
    _nestedScrollController.dispose();
    Get.delete<AnimeInfoStore>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 状态栏高度
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
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
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  title: InfoAppbarView(
                      subjectBasicData: subjectBasicData,
                      subjectsItem: subjectsInfo,
                      isPinned: isPinned),
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
                      child: InfoHeadView(
                        statusBarHeight: statusBarHeight,
                        contentHeight: _contentHeight,
                        subjectBasicData: subjectBasicData,
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: InfoSynopsisView(
            subjectsInfo: subjectsInfo,
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
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: Column(
          key: ValueKey<bool>(topButton),
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (topButton)
              FloatingActionButton(
                onPressed: () {
                  _nestedScrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(Icons.arrow_upward_rounded,
                    color: Theme.of(context).colorScheme.primary),
              ),
            const SizedBox(height: 5),
            Obx(() => userInfoStore.userInfo.value != null &&
                    subjectsInfo != null &&
                    subjectsInfo?.interest != null
                ? FloatingActionButton(
                    onPressed: () {
                      Get.dialog(
                          barrierDismissible: false, const EvaluateDialog());
                    },
                    child: Icon(
                      Icons.messenger,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const SizedBox.shrink()),
            if (subjectsInfo != null) ...[
              const SizedBox(height: 5),
              FloatingActionButton(
                onPressed: () {
                  Get.toNamed(RouteName.play, arguments: {
                    'subjectsInfo': subjectsInfo,
                  });
                },
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:anime_flow/controllers/my_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/pages/anime_info/inf_head.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/pages/anime_info/provider/anime_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'info_appBar.dart';
import 'synopsis.dart';

part 'evaluate_dialog.dart';

class AnimeInfoPage extends ConsumerStatefulWidget {
  final SubjectBasicData animeInfoExtra;

  const AnimeInfoPage({super.key, required this.animeInfoExtra});

  @override
  ConsumerState<AnimeInfoPage> createState() => _AnimeInfoPageState();
}

class _AnimeInfoPageState extends ConsumerState<AnimeInfoPage> {
  late final MyController myController;
  /// 内容区域的高度
  final double contentHeight = 200.0;
  bool isPinned = false;
  bool topButton = false;
  final nestedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    myController = Get.find<MyController>();
  }

  SubjectBasicData get subjectBasicData => widget.animeInfoExtra;

  @override
  void dispose() {
    nestedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectsInfo = ref.watch(
      animeInfoProvider(subjectBasicData.id).select(
            (asyncValue) => asyncValue.asData?.value,
      ),
    );

    // 状态栏高度
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            if (notification.depth == 0) {
              final bool isPinned =
                  notification.metrics.pixels >= contentHeight;
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
          controller: nestedScrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  title: InfoAppbar(
                      subjectBasicData: subjectBasicData,
                      isPinned: isPinned),
                  pinned: true,
                  floating: false,
                  snap: false,
                  // 动态设置背景色
                  elevation: isPinned ? 4.0 : 0.0,
                  forceElevated: isPinned,

                  // 展开高度计算：内容高度 + 状态栏 + Toolbar
                  expandedHeight:
                  contentHeight + statusBarHeight + kToolbarHeight,

                  /// 头部内容区域
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: InfoHeadView(
                        statusBarHeight: statusBarHeight,
                        contentHeight: contentHeight,
                        subjectBasicData: subjectBasicData,
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: InfoSynopsisView(
            subjectId: subjectBasicData.id,
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
                heroTag: 'top_${subjectBasicData.id}',
                onPressed: () {
                  nestedScrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(Icons.arrow_upward_rounded,
                    color: Theme.of(context).colorScheme.primary),
              ),
            const SizedBox(height: 5),
            Obx(() => myController.userInfo.value != null &&
                subjectsInfo != null &&
                subjectsInfo.interest != null
                ? FloatingActionButton(
              heroTag: 'evaluate_${subjectBasicData.id}',
              onPressed: () {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => InfoEvaluateDialog(
                    subjectsInfo: subjectsInfo,
                    onSaved: (updated) => ref
                        .read(animeInfoProvider(subjectBasicData.id).notifier)
                        .setAnimeInfo(updated),
                  ),
                );
              },
              child: Icon(
                Icons.messenger,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
                : const SizedBox.shrink()),
            const SizedBox(height: 5),
            FloatingActionButton(
              heroTag: 'play_${subjectBasicData.id}',
              onPressed: () =>
                  PlayRoute.fromData(subjectBasicData).push(context),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

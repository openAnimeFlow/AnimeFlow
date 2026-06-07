import 'package:anime_flow/providers/user/my_state_provider.dart';
import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/bangumi/episode_comments_item.dart';
import 'package:anime_flow/pages/play/content/introduce/index.dart';
import 'package:anime_flow/pages/play/controller/play_controller.dart';
import 'package:anime_flow/pages/play/controller/video_ui_controller.dart';
import 'package:anime_flow/pages/play/provider/episodes_provider.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/widget/danmaku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'comments/index.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView>
    with SingleTickerProviderStateMixin {
  final playController = Get.find<PlayController>();
  final videoUiStateController = Get.find<VideoUiStateController>();
  final List<String> tabs = ['简介', '吐槽'];
  late TabController tabController;
  bool isRequesting = false;
  List<EpisodeComment>? comments;
  int? lastRequestedEpisodeId;
  int currentEpisodeId = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this);
    tabController.addListener(onTabChanged);
  }

  @override
  void dispose() {
    tabController.removeListener(onTabChanged);
    tabController.dispose();
    super.dispose();
  }

  void onTabChanged() {
    if (tabController.index == 1 && comments == null && !isRequesting) {
      getComments();
    }
  }

  Future<void> getComments() async {
    final episodeId = currentEpisodeId;

    if (episodeId == lastRequestedEpisodeId) {
      return;
    }

    if (isRequesting) {
      return;
    }

    if (episodeId > 0) {
      isRequesting = true;
      lastRequestedEpisodeId = episodeId;

      try {
        final commentsData =
            await FlowRequest.episodeCommentsService(episodeId: episodeId);
        if (mounted && currentEpisodeId == episodeId) {
          setState(() {
            comments = commentsData;
          });
        }
      } catch (e) {
        LiggLogger().e(e);
        if (mounted && currentEpisodeId == episodeId) {
          setState(() {
            comments = [];
          });
        }
      } finally {
        isRequesting = false;
      }
    } else {
      lastRequestedEpisodeId = episodeId;
      if (mounted) {
        setState(() {
          comments = [];
        });
      }
    }
  }

  Future<void> onSendDanmaku(String text, int bgmUserId) async {
    final success = await playController.sendDanmaku(
      text,
      bgmUserId: bgmUserId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '弹幕发送成功' : '当前不支持发送弹幕',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        ref.listen<int>(
          episodesProvider.select((state) => state.episodeId),
          (previous, episodeId) {
            currentEpisodeId = episodeId;
            if (episodeId > 0 && episodeId != lastRequestedEpisodeId) {
              setState(() {
                comments = null;
              });
              if (tabController.index == 1) {
                getComments();
              }
            }
          },
        );
        currentEpisodeId = ref.read(episodesProvider).episodeId;
        return child!;
      },
      child: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TabBar(
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  dividerHeight: 0,
                  controller: tabController,
                  tabAlignment: TabAlignment.start,
                  isScrollable: true,
                  tabs: tabs.map((name) => Tab(text: name)).toList(),
                ),
                Obx(
                  () => playController.isWideScreen.value
                      ? const Spacer()
                      : Consumer(
                          builder: (context, ref, _) {
                            final userInfo = ref.watch(currentUserInfoProvider);
                            if (userInfo == null) {
                              return const SizedBox.shrink();
                            }
                            return SizedBox(
                              width: 200,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: DanmakuTextField(
                                  onFocusChange: (hasFocus) {
                                    if (hasFocus) {
                                      playController.stopPlaying();
                                      videoUiStateController.cancelUiTimer();
                                    } else {
                                      playController.startPlaying();
                                      videoUiStateController.hideControlsUi();
                                    }
                                  },
                                  onSend: (text) =>
                                      onSendDanmaku(text, userInfo.id),
                                ),
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  const IntroduceView(),
                  CommentsView(
                    comments: comments,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/episode_comments_item.dart';
import 'package:anime_flow/pages/play/content/introduce/index.dart';
import 'package:anime_flow/widget/video/ui/video_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'comments/index.dart';

class ContentView extends StatefulWidget {

  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView>
    with SingleTickerProviderStateMixin {
  late EpisodesState episodesState;
  late PlayController playPageController;
  final List<String> _tabs = ['简介', '吐槽'];
  late TabController _tabController;
  final GlobalKey _introduceKey = GlobalKey();
  final GlobalKey _commentKey = GlobalKey();
  bool _isRequesting = false;
  List<EpisodeComment>? comments;
  int? _lastRequestedEpisodeId; // 记录上次请求的 episodeId，避免重复请求
  Worker? _episodeIdWorker; // 监听 episodeId 变化

  @override
  void initState() {
    super.initState();
    episodesState = Get.find<EpisodesState>();
    _tabController = TabController(length: _tabs.length, vsync: this);
    playPageController = Get.find<PlayController>();
    
    // 监听 Tab 切换
    _tabController.addListener(_onTabChanged);
    
    // 监听 episodeId 变化
    _episodeIdWorker = ever(episodesState.episodeId, (episodeId) {
      // 当 episodeId 变化时，重置 comments 并重新获取
      if (episodeId > 0 && episodeId != _lastRequestedEpisodeId) {
        setState(() {
          comments = null;
        });
        if (_tabController.index == 1) {
          _getComments();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _episodeIdWorker?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // 当切换到"吐槽"标签页（索引1）且 comments 为 null 时，获取评论
    if (_tabController.index == 1 && comments == null && !_isRequesting) {
      _getComments();
    }
  }

  void _getComments() async {
    final episodeId = episodesState.episodeId.value;

    if (episodeId == _lastRequestedEpisodeId) {
      return;
    }

    if (_isRequesting) {
      return;
    }

    if (episodeId > 0) {
      // 标记正在请求中
      _isRequesting = true;
      _lastRequestedEpisodeId = episodeId;

      try {
        final commentsData =
            await BgmRequest.episodeCommentsService(episodeId: episodeId);
        // 再次检查 episodeId 是否仍然是当前值（防止请求期间 episodeId 变化）
        if (mounted && episodesState.episodeId.value == episodeId) {
          setState(() {
            comments = commentsData;
          });
        }
      } catch (e) {
        Logger().e(e);
        // 请求失败时也要检查 episodeId 是否仍然是当前值
        if (mounted && episodesState.episodeId.value == episodeId) {
          setState(() {
            comments = [];
          });
        }
      } finally {
        _isRequesting = false;
      }
    } else {
      _lastRequestedEpisodeId = episodeId;
      if (mounted) {
        setState(() {
          comments = [];
        });
      }
    }
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
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                dividerHeight: 0,
                controller: _tabController,
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                tabs: _tabs.map((name) => Tab(text: name)).toList(),
              ),
              Obx(
                    () => playPageController.isWideScreen.value
                    ? const Spacer()
                    : const SizedBox(
                  width: 200,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
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
                  key: _introduceKey),
                //吐槽
                CommentsView(
                  key: _commentKey,
                  comments: comments,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

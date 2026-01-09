import 'package:anime_flow/controllers/danmaku/danmaku_controller.dart';
import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/controllers/subject/subject_state_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/http/requests/damaku.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DanmakuView extends StatefulWidget {
  const DanmakuView({super.key});

  @override
  State<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends State<DanmakuView> {
  late SubjectStateController subjectStateController;
  late VideoStateController videoStateController;
  late DanmakuController danmakuController;
  late EpisodesController episodesController;
  bool isExpanded = false;
  bool _previousPlayingState = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    subjectStateController = Get.find<SubjectStateController>();
    videoStateController = Get.find<VideoStateController>();
    danmakuController = Get.find<DanmakuController>();
    episodesController = Get.find<EpisodesController>();

    // 记录初始播放状态
    _previousPlayingState = videoStateController.playing.value;

    // 监听播放状态变化，当从暂停变为播放时加载弹幕
    ever(videoStateController.playing, (bool playing) {
      if (playing && !_previousPlayingState) {
        // 从暂停变为播放，加载弹幕
        getDanmaku();
      }
      _previousPlayingState = playing;
    });
  }

  void getDanmaku() async {
    setState(() {
      _isLoading = true;
    });
    int episode = episodesController.episodeIndex.value;
    if (episode == 0) {
      return;
    }
    final bgmBangumiId = await DanmakuRequest.getDanDanBangumiIDByBgmBangumiID(
        subjectStateController.subjectId.value);
    final danmaku = await DanmakuRequest.getDanDanmaku(bgmBangumiId, episode);
    danmakuController.addDanmaku(danmaku);
    Get.log('弹幕数量为：${danmaku.length}');
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('弹幕源'),
                  const Spacer(),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    IconButton(
                        onPressed: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        icon: const Icon(Icons.vertical_align_bottom_sharp))
                ],
              ),
              Obx(
                () => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isExpanded ? 200 : 0,
                    child: ListView.builder(
                        itemCount: danmakuController.danmaku.length,
                        itemExtent: 56.0, // 固定item高度，提升滚动性能
                        cacheExtent: 200.0, // 限制缓存范围，减少内存占用
                        physics: const ClampingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final danmaku = danmakuController.danmaku[index];
                          return ListTile(
                              dense: true, // 使用紧凑模式减少padding
                              visualDensity: VisualDensity.compact,
                              title: Text(
                                danmaku.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                '${danmaku.time}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ));
                        })),
              )
            ],
          )),
    );
  }
}

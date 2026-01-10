import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/controllers/subject/subject_state_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/http/requests/damaku.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DanmakuCard extends StatefulWidget {
  const DanmakuCard({super.key});

  @override
  State<DanmakuCard> createState() => _DanmakuCardState();
}

class _DanmakuCardState extends State<DanmakuCard> {
  late SubjectStateController subjectStateController;
  late VideoStateController videoStateController;
  late EpisodesController episodesController;
  late PlayController playController;
  bool isExpanded = false;
  bool _isLoading = false;
  bool _hasDanmakuLoaded = false; // 标记弹幕是否已加载
  int _currentEpisode = 0; // 记录当前集数

  @override
  void initState() {
    super.initState();
    subjectStateController = Get.find<SubjectStateController>();
    videoStateController = Get.find<VideoStateController>();
    episodesController = Get.find<EpisodesController>();
    playController = Get.find<PlayController>();

    // 监听集数变化，当集数改变时重置弹幕加载状态
    ever(episodesController.episodeIndex, (int episode) {
      if (_currentEpisode != episode) {
        _currentEpisode = episode;
        _hasDanmakuLoaded = false;
        // 清空之前的弹幕
        playController.removeDanmaku();
      }
    });

    // 监听播放状态变化，只在视频第一次开始播放时加载弹幕
    // TODO 需要修改到当视频解析成功后调用
    ever(videoStateController.playing, (bool playing) {
      if (playing &&
          !_hasDanmakuLoaded &&
          episodesController.episodeIndex.value > 0) {
        // 视频开始播放且弹幕未加载，加载弹幕
        getDanmaku();
      }
    });
  }

  void getDanmaku() async {
    if (_hasDanmakuLoaded || _isLoading) {
      return; // 如果已经加载过或正在加载中，直接返回
    }

    setState(() {
      _isLoading = true;
    });

    try {
      int episode = episodesController.episodeIndex.value;
      if (episode == 0) {
        return;
      }

      final bgmBangumiId =
          await DanmakuRequest.getDanDanBangumiIDByBgmBangumiID(
              subjectStateController.subjectId.value);
      final danmaku = await DanmakuRequest.getDanDanmaku(bgmBangumiId, episode);
      playController.addDanmaku(danmaku);
      Get.log('弹幕数量为：${danmaku.length}');

      // 标记弹幕已加载
      _hasDanmakuLoaded = true;
    } catch (e) {
      Get.log('加载弹幕失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                  else ...[
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more),
                    )
                  ]
                ],
              ),
              Obx(
                () {
                  final allDanmakus = <Danmaku>[];
                  playController.danDanmakus.forEach((time, danmakus) {
                    allDanmakus.addAll(danmakus);
                  });
                  // 按时间排序
                  allDanmakus.sort((a, b) => a.time.compareTo(b.time));

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isExpanded ? 200 : 0,
                    child: ListView.builder(
                        itemCount: allDanmakus.length,
                        itemExtent: 56.0,
                        // 固定item高度，提升滚动性能
                        cacheExtent: 200.0,
                        // 缓存范围
                        physics: const ClampingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final danmaku = allDanmakus[index];
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
                        }),
                  );
                },
              )
            ],
          )),
    );
  }
}

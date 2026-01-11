import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DanmakuCard extends StatefulWidget {
  const DanmakuCard({super.key});

  @override
  State<DanmakuCard> createState() => _DanmakuCardState();
}

class _DanmakuCardState extends State<DanmakuCard> {
  late EpisodesController episodesController;
  late PlayController playController;
  bool isExpanded = false;
  int _currentEpisode = 0; // 记录当前集数

  @override
  void initState() {
    super.initState();
    episodesController = Get.find<EpisodesController>();
    playController = Get.find<PlayController>();

    // 监听集数变化，当集数改变时重置弹幕加载状态
    ever(episodesController.episodeIndex, (int episode) {
      if (_currentEpisode != episode) {
        _currentEpisode = episode;
        // 清空之前的弹幕
        playController.removeDanmaku();
      }
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
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more),
                  )
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

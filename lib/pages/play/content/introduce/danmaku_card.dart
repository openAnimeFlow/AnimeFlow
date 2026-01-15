import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/PlayPageController.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/utils/formatUtil.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DanmakuCard extends StatefulWidget {
  const DanmakuCard({super.key});

  @override
  State<DanmakuCard> createState() => _DanmakuCardState();
}

class _DanmakuCardState extends State<DanmakuCard> {
  late EpisodesState episodesController;
  late PlayController playController;
  bool isExpanded = false;
  int _currentEpisode = 0; // 记录当前集数

  @override
  void initState() {
    super.initState();
    episodesController = Get.find<EpisodesState>();
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

  /// 从 source 字段中提取平台名称（如 [Gamer]Sabrina2001 -> Gamer）
  String _extractPlatform(String source) {
    final regex = RegExp(r'\[([^\]]+)\]');
    final match = regex.firstMatch(source);
    return match?.group(1) ?? '弹弹Play';
  }

  /// 统计各平台弹幕数量
  Map<String, int> _countByPlatform(List<Danmaku> danmakus) {
    final Map<String, int> counts = {};
    for (var danmaku in danmakus) {
      final platform = _extractPlatform(danmaku.source);
      counts[platform] = (counts[platform] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allDanmakus = <Danmaku>[];
      playController.danDanmakus.forEach((time, danmakus) {
        allDanmakus.addAll(danmakus);
      });
      
      // 过滤掉被隐藏平台的弹幕
      final filteredDanmakus = allDanmakus.where((danmaku) {
        final platform = _extractPlatform(danmaku.source);
        return !playController.isPlatformHidden(platform);
      }).toList();
      
      // 按时间排序
      filteredDanmakus.sort((a, b) => a.time.compareTo(b.time));
      
      // 统计各平台弹幕数量
      final platformCounts = _countByPlatform(allDanmakus);
      final sortedPlatforms = platformCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)); // 按数量降序排列
      
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('弹幕源:',style: TextStyle(fontWeight: FontWeight.bold),),
                  if (allDanmakus.isNotEmpty)
                    ...[
                      const SizedBox(width: 5),
                      Text(
                        '总装填(${allDanmakus.length})条弹幕',
                        style: Theme.of(context).textTheme.bodySmall
                      ),
                      const Spacer(),
                    ]
                  else ...[
                    const Spacer(),
                  ],
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
              // 平台统计信息
              if (isExpanded && sortedPlatforms.isNotEmpty)
                Obx(() => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: sortedPlatforms.map((entry) {
                      final platform = entry.key;
                      final isHidden = playController.isPlatformHidden(platform);
                      return ActionChip(
                        label: Text('${entry.key}: ${entry.value}'),
                        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          decoration: isHidden ? TextDecoration.lineThrough : null,
                          color: isHidden 
                              ? Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)
                              : null,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: isHidden 
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : null,
                        onPressed: () {
                          playController.togglePlatformVisibility(platform);
                        },
                      );
                    }).toList(),
                  ),
                )),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isExpanded ? 300 : 0,
                child: ListView.builder(
                    itemCount: filteredDanmakus.length,
                    itemExtent: 56.0,
                    // 固定item高度，提升滚动性能
                    cacheExtent: 200.0,
                    // 缓存范围
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final danmaku = filteredDanmakus[index];
                      return ListTile(
                          dense: true, // 使用紧凑模式减少padding
                          visualDensity: VisualDensity.compact,
                          title: Text(
                            danmaku.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '${FormatUtil.formatDanmakuTime(danmaku.time)} · ${_extractPlatform(danmaku.source)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ));
                    }),
              ),
            ],
          ),
        ),
      );
    });
  }
}

import 'package:anime_flow/http/requests/damaku_request.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_search_response.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:anime_flow/utils/format_time_util.dart';
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
  late PlaySubjectState subjectState;

  final danmakuFieldController = TextEditingController();

  bool isExpanded = false;
  int _currentEpisode = 0; // 记录当前集数
  // DanmakuSearchResponse? danmakuSearchResponse;

  @override
  void initState() {
    super.initState();
    episodesController = Get.find<EpisodesState>();
    playController = Get.find<PlayController>();
    subjectState = Get.find<PlaySubjectState>();
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

  //搜索animes
  // Future<void> _searchAnimes(String query, StateSetter setDialogState) async {
  //   setDialogState(() {
  //     isSearchLoading = true;
  //     danmakuSearchResponse = null;
  //   });
  //   try {
  //     final response = await DanmakuRequest.getDanmakuSearchResponse(query);
  //     setDialogState(() {
  //       danmakuSearchResponse = response;
  //       isSearchLoading = false;
  //     });
  //   } catch (e) {
  //     setDialogState(() {
  //       isSearchLoading = false;
  //     });
  //   }
  // }

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
                  const Text(
                    '弹幕源:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (allDanmakus.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Text('总装填(${allDanmakus.length})条弹幕',
                        style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                  ] else ...[
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isExpanded ? 300 : 0,
                child: Column(
                  children: [
                    if (sortedPlatforms.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(subjectState.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              danmakuFieldController.text = subjectState.name;
                              Get.dialog(danmakuDialog);
                            },
                            child: const Text('切换弹幕'),
                          )
                        ],
                      ),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: sortedPlatforms.map((entry) {
                            final platform = entry.key;
                            final isHidden =
                                playController.isPlatformHidden(platform);
                            return ActionChip(
                              label: Text('${entry.key}: ${entry.value}'),
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    decoration: isHidden
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isHidden
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withValues(alpha: 0.5)
                                        : null,
                                  ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: isHidden
                                  ? Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                  : null,
                              onPressed: () {
                                playController
                                    .togglePlatformVisibility(platform);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(0),
                        itemCount: filteredDanmakus.length,
                        // 固定item高度，提升滚动性能
                        itemExtent: 30.0,
                        // 缓存范围
                        cacheExtent: 200.0,
                        physics: const ClampingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final danmaku = filteredDanmakus[index];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  danmaku.message,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${FormatTimeUtil.formatDanmakuTime(danmaku.time)} · ${_extractPlatform(danmaku.source)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget get danmakuDialog {
    DanmakuSearchResponse? danmakuSearchResponse;
    bool isSearchLoading = false;
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) {
        return  AlertDialog(
            icon: const Icon(Icons.subtitles),
            title: const Text('修改弹幕'),
            titleTextStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: danmakuFieldController,
                      decoration: const InputDecoration(
                        hintText: '请输入标题',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isSearchLoading) ...[
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ] else if (danmakuSearchResponse == null) ...[
                      const SizedBox.shrink()
                    ] else ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('搜索结果:'),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                          minHeight: 100,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: danmakuSearchResponse!.animes.length,
                          itemBuilder: (context, index) {
                            final anime = danmakuSearchResponse!.animes[index];
                            return ListTile(
                              title: Text(anime.animeTitle,style: Theme.of(context).textTheme.bodyLarge,),
                              onTap: () async {
                                final episodes = await DanmakuRequest.getDanDanEpisodesByDanDanBangumiID(anime.animeId);
                                 Get.back();
                                if (context.mounted) {
                                  _showEpisodesDialog(context, episodes, anime.animeTitle);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  if (danmakuFieldController.text.isNotEmpty) {
                    setDialogState(() {
                      isSearchLoading = true;
                      danmakuSearchResponse = null;
                    });
                    try {
                      final response =
                          await DanmakuRequest.getDanmakuSearchResponse(
                              danmakuFieldController.text);
                      setDialogState(() {
                        danmakuSearchResponse = response;
                        isSearchLoading = false;
                      });
                    } catch (e) {
                      setDialogState(() {
                        isSearchLoading = false;
                      });
                    }
                  }
                },
                child: const Text('提交'),
              )
            ],
        );
      },
    );
  }

  /// 显示剧集选择弹窗
  void _showEpisodesDialog(BuildContext context, DanmakuEpisodeResponse episodesResponse, String animeTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return  AlertDialog(
            title: Text(animeTitle),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SizedBox(
              width: double.maxFinite,
              child: episodesResponse.episodes.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('暂无剧集数据'),
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 400,
                        minHeight: 200,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: episodesResponse.episodes.length,
                        itemBuilder: (context, index) {
                          final episode = episodesResponse.episodes[index];
                          return ListTile(
                            title: Text(
                              episode.episodeTitle,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            onTap: ()  async {
                              final danmaku = await DanmakuRequest.getDanDanmakuByEpisodeID(episode.episodeId);
                              playController.removeDanmaku();
                              playController.addDanmaku(danmaku);
                              Get.back();
                            },
                          );
                        },
                      ),
                    ),
            ),),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('关闭'),
              ),
            ],
        );
      },
    );
  }
}

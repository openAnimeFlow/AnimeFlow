import 'package:anime_flow/network/requests/flow_request.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_module.dart';
import 'package:anime_flow/models/item/danmaku/danmaku_search_response.dart';
import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DanmakuCard extends ConsumerStatefulWidget {
  const DanmakuCard({super.key});

  @override
  ConsumerState<DanmakuCard> createState() => _DanmakuCardState();
}

class _DanmakuCardState extends ConsumerState<DanmakuCard>
    with SingleTickerProviderStateMixin {
  late final PlaySession playController;
  final danmakuFieldController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    playController = ref.read(playSessionProvider);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    danmakuFieldController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  /// 从 source 字段中提取平台名称（如 [Gamer]Sabrina2001 -> Gamer）
  String extractPlatform(String source) {
    final regex = RegExp(r'\[([^\]]+)\]');
    final match = regex.firstMatch(source);
    return match?.group(1) ?? '弹弹Play';
  }

  /// 统计各平台弹幕数量
  Map<String, int> countByPlatform(List<Danmaku> danmakus) {
    final counts = <String, int>{};
    for (final danmaku in danmakus) {
      final platform = extractPlatform(danmaku.source);
      counts[platform] = (counts[platform] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final danDanmakus = ref.watch(
      playStateProvider.select((s) => s.danDanmakus),
    );
    final hiddenPlatforms = ref.watch(
      playStateProvider.select((s) => s.hiddenPlatforms),
    );
    return Builder(builder: (context) {
      final allDanmakus = <Danmaku>[];
      danDanmakus.forEach((time, danmakus) {
        allDanmakus.addAll(danmakus);
      });

      // 过滤掉被隐藏平台的弹幕
      final filteredDanmakus = allDanmakus.where((danmaku) {
        final platform = extractPlatform(danmaku.source);
        return !hiddenPlatforms.contains(platform);
      }).toList();

      // 按时间排序
      filteredDanmakus.sort((a, b) => a.time.compareTo(b.time));

      // 统计各平台弹幕数量
      final platformCounts = countByPlatform(allDanmakus);
      final sortedPlatforms = platformCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

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
                    onPressed: _toggleExpanded,
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.expand_more),
                    ),
                  )
                ],
              ),
              // 平台统计信息
              SizeTransition(
                sizeFactor: _expandAnimation,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer(builder: (context, ref, child) {
                      final subjectName = ref.watch(playExtraProvider
                          .select((e) => e.playExtra.subjectName));
                      return Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                subjectName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              danmakuFieldController.text = subjectName;
                              showDialog<void>(
                                context: context,
                                builder: (_) => danmakuDialog,
                              );
                            },
                            child: const Text('切换弹幕'),
                          )
                        ],
                      );
                    }),
                    if (sortedPlatforms.isNotEmpty)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: sortedPlatforms.map((entry) {
                            final platform = entry.key;
                            final isHidden = hiddenPlatforms.contains(platform);
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
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(0),
                        itemCount: filteredDanmakus.length,
                        itemExtent: 30.0,
                        scrollCacheExtent:
                            const ScrollCacheExtent.pixels(200.0),
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
                                '${FormatTimeUtil.formatDanmakuTime(danmaku.time)} · ${extractPlatform(danmaku.source)}',
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
      builder: (BuildContext dialogContext, StateSetter setDialogState) {
        return AlertDialog(
          icon: const Icon(Icons.subtitles),
          title: const Text('切换弹幕'),
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
                        itemBuilder: (listContext, index) {
                          final anime = danmakuSearchResponse!.animes[index];
                          return ListTile(
                            title: Text(
                              anime.animeTitle,
                              style: Theme.of(listContext).textTheme.bodyLarge,
                            ),
                            onTap: () async {
                              final episodes = await FlowRequest
                                  .getDanDanEpisodesByDanDanBangumiID(
                                      anime.animeId);
                              if (!dialogContext.mounted) return;
                              dialogContext.pop();
                              if (!mounted) return;
                              _showEpisodesDialog(
                                context,
                                episodes,
                                anime.animeTitle,
                              );
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
              onPressed: () => Navigator.of(dialogContext).pop(),
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
                    final response = await FlowRequest.searchResponse(
                      danmakuFieldController.text,
                    );
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

  void _showEpisodesDialog(
    BuildContext context,
    DanmakuEpisodeResponse episodesResponse,
    String animeTitle,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(animeTitle),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SizedBox(
              width: double.maxFinite,
              child: episodesResponse.episodes.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('鏆傛棤鍓ч泦鏁版嵁'),
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
                            onTap: () async {
                              final danmaku =
                                  await FlowRequest.getDanDanmakuByEpisodeID(
                                      episode.episodeId);
                              if (!context.mounted) return;
                              playController.removeDanmaku();
                              playController.addDanmakuAll(danmaku);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('鍏抽棴'),
            ),
          ],
        );
      },
    );
  }
}

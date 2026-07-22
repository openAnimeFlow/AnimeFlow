import 'dart:async';
import 'dart:convert';

import 'package:anime_flow/constants/layout_constant.dart';
import 'package:anime_flow/crawler/itme/anti_crawler_config.dart';
import 'package:anime_flow/models/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/play/video/resources_item.dart';
import 'package:anime_flow/pages/play/providers/video_source_provider.dart';
import 'package:anime_flow/providers/captcha/captcha_provider.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _SourceEpisodeMode { matched, all }

class VideoSourceDrawers extends ConsumerStatefulWidget {
  final Function(String url)? onVideoUrlSelected;
  final VideoSourceNotifier videoSourceController;
  final String subjectName;
  final bool isBottomSheet;
  final ScrollController? scrollController;
  final DraggableScrollableController? draggableController;

  const VideoSourceDrawers({
    super.key,
    this.onVideoUrlSelected,
    this.isBottomSheet = false,
    this.scrollController,
    this.draggableController,
    required this.videoSourceController,
    required this.subjectName,
  });

  @override
  ConsumerState<VideoSourceDrawers> createState() => _VideoSourceDrawersState();
}

class _VideoSourceDrawersState extends ConsumerState<VideoSourceDrawers> {
  static const double _minSheetSize = 0.3;
  static const double _initialSheetSize = 0.52;
  static const double _maxSheetSize = 0.95;

  final logger = LiggLogger();
  _SourceEpisodeMode _sourceEpisodeMode = _SourceEpisodeMode.matched;
  String? _selectedLineName;
  final _searchController = TextEditingController();
  int? _drawerSelectedWebsiteIndex;
  bool _followInitialAutoSelection = true;
  late final ScrollController _fallbackScrollController;

  ScrollController get _scrollController =>
      widget.scrollController ?? _fallbackScrollController;

  @override
  void initState() {
    super.initState();
    _fallbackScrollController = ScrollController();
    _searchController.text = widget.subjectName;
  }

  void _setSelectedWebsite(int index) {
    _followInitialAutoSelection = false;
    _drawerSelectedWebsiteIndex = index;
    widget.videoSourceController.setSelectedWebsiteIndex(index);
    setState(() {
      _sourceEpisodeMode = _SourceEpisodeMode.matched;
      _selectedLineName = null;
    });
  }

  void _performSearch() {
    String searchQuery = _searchController.text;
    if (searchQuery.isNotEmpty) {
      widget.videoSourceController.setSelectedWebsiteIndex(0);
      _followInitialAutoSelection = true;
      _drawerSelectedWebsiteIndex = 0;
      setState(() {
        _sourceEpisodeMode = _SourceEpisodeMode.matched;
        _selectedLineName = null;
      });
      widget.videoSourceController.initResources(searchQuery);
    }
  }

  int _getDrawerSelectedIndex(List<ResourcesItem> dataSource) {
    final controller = widget.videoSourceController;
    final providerIndex = controller.selectedWebsiteIndex >= dataSource.length
        ? 0
        : controller.selectedWebsiteIndex;

    if (_drawerSelectedWebsiteIndex == null ||
        _drawerSelectedWebsiteIndex! >= dataSource.length) {
      _drawerSelectedWebsiteIndex = providerIndex;
    }

    if (_followInitialAutoSelection &&
        _drawerSelectedWebsiteIndex != providerIndex) {
      _drawerSelectedWebsiteIndex = providerIndex;
    }

    if (_followInitialAutoSelection && controller.webSiteTitle.isNotEmpty) {
      _followInitialAutoSelection = false;
    }

    return _drawerSelectedWebsiteIndex ?? providerIndex;
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _fallbackScrollController.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(videoSourceProvider);
    if (widget.isBottomSheet) {
      return buildBottomSheetContent(context);
    }
    return buildSideDrawerContent(context);
  }

  /// 底部抽屉内容
  Widget buildBottomSheetContent(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 20, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDragHandle(context),
            buildHeader(),
            _manualSearch(),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final dataSource = widget.videoSourceController.videoResources;
                if (dataSource.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildWebsiteSelector(dataSource: dataSource);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  final videoSourceController = widget.videoSourceController;
                  final dataSource = videoSourceController.videoResources;
                  if (dataSource.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final selectedIndex = _getDrawerSelectedIndex(dataSource);
                  return _buildVideoSource(
                    dataSource: dataSource,
                    selectedIndex: selectedIndex,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: widget.draggableController == null
          ? null
          : (details) {
              final controller = widget.draggableController!;
              if (!controller.isAttached) return;
              final height = MediaQuery.sizeOf(context).height;
              final nextSize =
                  (controller.size - details.primaryDelta! / height).clamp(
                _minSheetSize,
                _maxSheetSize,
              );
              controller.jumpTo(nextSize);
            },
      onVerticalDragEnd: widget.draggableController == null
          ? null
          : (_) {
              final controller = widget.draggableController!;
              if (!controller.isAttached) return;
              final currentSize = controller.size;
              final snapTargets = [
                _minSheetSize,
                _initialSheetSize,
                _maxSheetSize,
              ];
              final target = snapTargets.reduce(
                (a, b) =>
                    (currentSize - a).abs() < (currentSize - b).abs() ? a : b,
              );
              controller.animateTo(
                target,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
              );
            },
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  /// 侧边抽屉内容
  Widget buildSideDrawerContent(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: LayoutConstant.playContentWidth,
        height: MediaQuery.of(context).size.height,
        child: Container(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top, left: 16, right: 16),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(),
              _manualSearch(),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final videoSourceController = widget.videoSourceController;
                  final dataSource = videoSourceController.videoResources;
                  if (dataSource.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _buildWebsiteSelector(dataSource: dataSource);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final videoSourceController = widget.videoSourceController;
                    final dataSource = videoSourceController.videoResources;
                    if (dataSource.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final selectedIndex = _getDrawerSelectedIndex(dataSource);
                    return _buildVideoSource(
                      dataSource: dataSource,
                      selectedIndex: selectedIndex,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 标题行
  Widget buildHeader() {
    return Row(
      children: [
        Text(
          '数据源',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
            decoration: TextDecoration.none,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _manualSearch() {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Text(
            '手动搜索',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
              child: Material(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '手动搜索资源',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              onSubmitted: (value) {
                _performSearch();
              },
            ),
          ))
        ],
      ),
    );
  }

  // 数据源选择器
  Widget _buildWebsiteSelector({required List<ResourcesItem> dataSource}) {
    final selectedIndex = _getDrawerSelectedIndex(dataSource);
    return SizedBox(
        height: 40,
        child: Row(
          children: [
            Icon(
              Icons.public,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Expanded(
                child: ListView.builder(
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.horizontal,
                    itemCount: dataSource.length,
                    itemBuilder: (context, index) {
                      final data = dataSource[index];
                      final isSelected = selectedIndex == index;

                      // final currentEpisodeCount = resource.episodeResources
                      //     .where((item) => item.episodes.any((ep) =>
                      //         ep.episodeSort ==
                      //         episodesController.episodeIndex.value))
                      //     .length;

                      return GestureDetector(
                        onTap: () => _setSelectedWebsite(index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipOval(
                                child: AnimationNetworkImage(
                                    width: 24,
                                    height: 24,
                                    url: data.websiteIcon),
                              ),
                              if (data.isLoading) ...[
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ] else if (data.needsCaptcha) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                              ] else if (data.errorMessage != null) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.error_outline,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ] else if (data.episodeResources.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    })),
          ],
        ));
  }

  Widget _buildVideoSource({
    required List<ResourcesItem> dataSource,
    required int selectedIndex,
  }) {
    final videoSourceController = widget.videoSourceController;
    if (selectedIndex >= dataSource.length) {
      return const SizedBox.shrink();
    }

    final selectedResource = dataSource[selectedIndex];
    final episodeResources = selectedResource.episodeResources;

    if (selectedResource.needsCaptcha) {
      return _buildCaptchaRequired(selectedResource);
    }

    if (selectedResource.isLoading) {
      return _buildResourceStatusView(
        icon: const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        title: '正在获取 ${selectedResource.websiteName} 的资源',
        message: '当前站点正在重新检索，请稍候片刻。',
      );
    }

    if (selectedResource.errorMessage != null) {
      return _buildResourceStatusView(
        icon: Icon(
          Icons.error_outline,
          size: 44,
          color: Theme.of(context).colorScheme.error,
        ),
        title: '${selectedResource.websiteName} 请求失败',
        message: selectedResource.errorMessage!,
        action: ElevatedButton(
          onPressed: () => videoSourceController
              .retryResources(selectedResource.websiteName),
          child: const Text('点击重试'),
        ),
      );
    }

    if (episodeResources.isEmpty) {
      return _buildResourceStatusView(
        icon: Icon(
          Icons.search_off_rounded,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: '${selectedResource.websiteName} 暂未搜到资源',
        message: '没有检索到可用播放源。你可以稍后重试，或切换其他站点。',
        action: ElevatedButton(
          onPressed: () => videoSourceController
              .retryResources(selectedResource.websiteName),
          child: const Text('重新搜索'),
        ),
      );
    }
    final episodeIndex = videoSourceController.currentEpisodeIndex;
    final lineNames = _buildLineNames(episodeResources);
    final selectedLineName =
        lineNames.contains(_selectedLineName) ? _selectedLineName : null;
    final filteredEpisodeResources = _filterResourcesByLine(
      episodeResources,
      selectedLineName,
    );

    // 预过滤：只保留有匹配当前剧集的资源项
    final matchedResources = filteredEpisodeResources
        .where(
            (item) => item.episodes.any((ep) => ep.episodeSort == episodeIndex))
        .toList();

    final excludedEpisodesCount = filteredEpisodeResources
        .expand((item) =>
            item.episodes.where((ep) => ep.episodeSort != episodeIndex))
        .length;

    return Material(
      child: Column(
        children: [
          _buildLineFilter(
            lineNames: lineNames,
            selectedLineName: selectedLineName,
          ),
          const SizedBox(height: 8),
          _buildEpisodeModeSelector(
            matchedCount: matchedResources.length,
            allCount: filteredEpisodeResources.fold<int>(
                0, (sum, item) => sum + item.episodes.length),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _sourceEpisodeMode == _SourceEpisodeMode.all
                ? _buildAllEpisodeSources(
                    episodeResources: filteredEpisodeResources,
                    selectedResource: selectedResource,
                  )
                : _buildMatchedEpisodeSources(
                    matchedResources: matchedResources,
                    selectedResource: selectedResource,
                    episodeIndex: episodeIndex,
                    excludedEpisodesCount: excludedEpisodesCount,
                  ),
          ),
        ],
      ),
    );
  }

  List<String> _buildLineNames(List<EpisodeResourcesItem> episodeResources) {
    final names = <String>[];
    final seen = <String>{};
    for (final item in episodeResources) {
      final lineName = item.lineNames.trim().isEmpty ? '未命名线路' : item.lineNames;
      if (seen.add(lineName)) {
        names.add(lineName);
      }
    }
    return names;
  }

  List<EpisodeResourcesItem> _filterResourcesByLine(
    List<EpisodeResourcesItem> episodeResources,
    String? lineName,
  ) {
    if (lineName == null) {
      return episodeResources;
    }
    return episodeResources.where((item) {
      final itemLineName =
          item.lineNames.trim().isEmpty ? '未命名线路' : item.lineNames;
      return itemLineName == lineName;
    }).toList(growable: false);
  }

  Widget _buildLineFilter({
    required List<String> lineNames,
    required String? selectedLineName,
  }) {
    if (lineNames.length <= 1) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('全部线路'),
                    selected: selectedLineName == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedLineName = null;
                      });
                    },
                  ),
                ),
                ...lineNames.map(
                  (lineName) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(lineName),
                      selected: selectedLineName == lineName,
                      onSelected: (_) {
                        setState(() {
                          _selectedLineName = lineName;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeModeSelector({
    required int matchedCount,
    required int allCount,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<_SourceEpisodeMode>(
        segments: [
          ButtonSegment(
            value: _SourceEpisodeMode.matched,
            icon: const Icon(Icons.rule_rounded, size: 18),
            label: Text('匹配当前集($matchedCount)'),
          ),
          ButtonSegment(
            value: _SourceEpisodeMode.all,
            icon: const Icon(Icons.format_list_numbered_rounded, size: 18),
            label: Text('全部集数($allCount)'),
          ),
        ],
        selected: {_sourceEpisodeMode},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          setState(() {
            _sourceEpisodeMode = selection.first;
          });
        },
      ),
    );
  }

  Widget _buildMatchedEpisodeSources({
    required List<EpisodeResourcesItem> matchedResources,
    required ResourcesItem selectedResource,
    required int episodeIndex,
    required int excludedEpisodesCount,
  }) {
    if (matchedResources.isEmpty) {
      return _buildResourceStatusView(
        icon: Icon(
          Icons.playlist_remove_rounded,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: '当前剧集暂无可用播放源',
        message: excludedEpisodesCount > 0
            ? '当前选中剧集不在这些结果里。你可以切到“全部集数”手动指定资源站集数。'
            : '当前剧集没有匹配到对应播放源。',
      );
    }

    return ListView.builder(
      controller: widget.isBottomSheet ? _scrollController : null,
      padding: EdgeInsets.zero,
      itemCount: matchedResources.length,
      itemExtent: 95,
      itemBuilder: (context, index) {
        final resourceItem = matchedResources[index];
        final currentEpisode = resourceItem.episodes.firstWhere(
          (ep) => ep.episodeSort == episodeIndex,
        );
        return _buildSource(
          currentEpisode,
          resourceItem,
          baseUrl: selectedResource.baseUrl,
          websiteName: selectedResource.websiteName,
          websiteIcon: selectedResource.websiteIcon,
        );
      },
    );
  }

  Widget _buildAllEpisodeSources({
    required List<EpisodeResourcesItem> episodeResources,
    required ResourcesItem selectedResource,
  }) {
    final expandedItems = episodeResources.expand((item) {
      return item.episodes.map((ep) => (resource: item, episode: ep));
    }).toList(growable: false);

    if (expandedItems.isEmpty) {
      return _buildResourceStatusView(
        icon: Icon(
          Icons.search_off_rounded,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: '暂无可选集数',
        message: '当前站点没有返回可用播放集数。',
      );
    }

    return ListView.builder(
      controller: widget.isBottomSheet ? _scrollController : null,
      padding: EdgeInsets.zero,
      itemCount: expandedItems.length,
      itemExtent: 95,
      itemBuilder: (context, index) {
        final entry = expandedItems[index];
        return _buildSource(
          entry.episode,
          entry.resource,
          baseUrl: selectedResource.baseUrl,
          websiteName: selectedResource.websiteName,
          websiteIcon: selectedResource.websiteIcon,
        );
      },
    );
  }

  Widget _buildResourceStatusView({
    required Widget icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: 16),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptchaRequired(ResourcesItem resource) {
    return CaptchaView(
      key: ValueKey(resource.websiteName),
      resource: resource,
      dataSourceController: widget.videoSourceController,
      subjectName: widget.subjectName,
    );
  }

  /// 匹配度徽章
  Widget _buildMatchRatioBadge(double ratio) {
    final cs = Theme.of(context).colorScheme;
    final (Color color, Color containerColor) = ratio >= 0.9
        ? (cs.primary, cs.primaryContainer)
        : ratio >= 0.7
            ? (cs.tertiary, cs.tertiaryContainer)
            : ratio >= 0.5
                ? (cs.secondary, cs.secondaryContainer)
                : (cs.error, cs.errorContainer);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '${(ratio * 100).round()}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSource(Episode episode, EpisodeResourcesItem item,
      {required String websiteName,
      required String websiteIcon,
      required String baseUrl}) {
    final videoUrl = widget.videoSourceController.videoUrl;
    final isSelected = baseUrl + episode.like == videoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                width: 2.5,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
      child: Card.filled(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () async {
            try {
              context.pop();
              final videoUrl = baseUrl + episode.like;
              widget.videoSourceController.bindManualSourceForCurrentEpisode(
                websiteName: websiteName,
                websiteIcon: websiteIcon,
                videoUrl: videoUrl,
              );
              widget.onVideoUrlSelected?.call(videoUrl);
            } catch (e) {
              logger.e('获取视频源失败', error: e);
              NotificationToast.show('错误', '获取视频源失败: $e');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          text: item.subjectsTitle,
                          children: [
                            TextSpan(
                              text:
                                  ' 第${episode.episodeSort.toString().padLeft(2, '0')}集',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '线路:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.lineNames,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Icon(
                      Icons.link,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const Spacer(),
                    const Text('匹配度:'),
                    const SizedBox(width: 4),
                    _buildMatchRatioBadge(item.matchRatio),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 验证ui
class CaptchaView extends StatefulWidget {
  const CaptchaView({
    super.key,
    required this.resource,
    required this.dataSourceController,
    required this.subjectName,
  });

  final ResourcesItem resource;
  final VideoSourceNotifier dataSourceController;
  final String subjectName;

  @override
  State<CaptchaView> createState() => _CaptchaViewState();
}

class _CaptchaViewState extends State<CaptchaView> {
  CaptchaProvider? _provider;
  Timer? _verifyTimer;
  StreamSubscription? _imageSub;
  final _codeController = TextEditingController();
  String? _imageData;
  bool _sessionActive = false;
  bool _isSubmitting = false;
  bool _isAutoVerifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    _disposeSession();
    super.dispose();
  }

  void _disposeSession() {
    _imageSub?.cancel();
    _imageSub = null;
    _verifyTimer?.cancel();
    _verifyTimer = null;
    _provider?.dispose();
    _provider = null;
    _sessionActive = false;
    _isSubmitting = false;
    _isAutoVerifying = false;
    _imageData = null;
  }

  void _startVerification() {
    final config = widget.resource.antiCrawlerConfig;
    if (config == null) return;
    final keyword = widget.subjectName;

    _disposeSession();
    _provider = CaptchaProvider();
    final name = widget.resource.websiteName;
    final url = widget.resource.searchUrl.replaceFirst('{keyword}', keyword);

    if (config.captchaType == CaptchaType.autoClickButton) {
      setState(() {
        _sessionActive = true;
        _isAutoVerifying = true;
      });
      _provider!.loadForButtonClick(
        url: url,
        buttonXpath: config.captchaButton,
        pluginName: name,
        onVerified: () => _onVerified(name),
      );
    } else {
      setState(() {
        _sessionActive = true;
        _imageData = null;
        _isSubmitting = false;
      });

      _imageSub = _provider!.onCaptchaImageUrl.listen((imageUrl) {
        if (imageUrl != null && mounted) {
          setState(() {
            _imageData = imageUrl;
            if (_isSubmitting) {
              _isSubmitting = false;
              _codeController.clear();
              _verifyTimer?.cancel();
              _verifyTimer = null;
            }
          });
        }
      });

      _provider!.loadForCaptcha(
        url,
        config.captchaImage,
        inputXpath: config.captchaInput,
      );
    }
  }

  void _onVerified(String websiteName) {
    if (!mounted) return;
    _disposeSession();
    widget.dataSourceController.markCaptchaVerified(websiteName);
    setState(() {});
    NotificationToast.show('验证成功', '正在重新检索，请稍候…');
    Future.delayed(const Duration(seconds: 2), () {
      widget.dataSourceController.retryResources(websiteName);
    });
  }

  Future<void> _submit() async {
    final config = widget.resource.antiCrawlerConfig;
    if (config == null || _isSubmitting) return;
    if (_codeController.text.trim().isEmpty) {
      NotificationToast.show('提示', '请输入验证码');
      return;
    }
    setState(() => _isSubmitting = true);
    final name = widget.resource.websiteName;

    await _provider?.submitCaptcha(
      captchaCode: _codeController.text.trim(),
      inputXpath: config.captchaInput,
      buttonXpath: config.captchaButton,
      pluginName: name,
      onVerified: () => _onVerified(name),
    );

    if (_sessionActive && mounted) {
      _verifyTimer?.cancel();
      _verifyTimer = Timer(const Duration(seconds: 8), () async {
        if (!_sessionActive || !mounted) return;
        setState(() {
          _isSubmitting = false;
          _codeController.clear();
        });
        NotificationToast.show('提示', '验证码可能有误，请重新输入');
        await _reloadCaptchaImage();
      });
    }
  }

  /// 重新拉取验证码图
  Future<void> _reloadCaptchaImage() async {
    final config = widget.resource.antiCrawlerConfig;
    final p = _provider;
    if (config == null || p == null || !_sessionActive || _isAutoVerifying) {
      return;
    }
    _verifyTimer?.cancel();
    _verifyTimer = null;
    if (!mounted) return;
    setState(() {
      _imageData = null;
      _isSubmitting = false;
    });
    await p.reloadCaptchaImage(config.captchaImage,
        inputXpath: config.captchaInput);
  }

  void _cancel() {
    final name = widget.resource.websiteName;
    final provider = _provider;
    _provider = null;
    _imageSub?.cancel();
    _imageSub = null;
    _verifyTimer?.cancel();
    _verifyTimer = null;
    setState(() {
      _sessionActive = false;
      _isSubmitting = false;
      _isAutoVerifying = false;
      _imageData = null;
      _codeController.clear();
    });
    provider?.saveAndUnload(name).then((_) {
      provider.dispose();
      widget.dataSourceController.retryResources(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resource;

    if (!_sessionActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('${r.websiteName} 需要验证码验证',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _startVerification,
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: const Text('进行验证'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      widget.dataSourceController.retryResources(r.websiteName),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重试'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isAutoVerifying) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${r.websiteName} 正在自动完成验证，请稍候',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _cancel,
              child: Text('取消',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: View.of(context).viewInsets.bottom),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 36, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text('${r.websiteName} 验证码验证',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 16),
                if (_imageData == null) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('正在加载验证码图片...'),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: (_isSubmitting || _imageData == null)
                          ? null
                          : () {
                              _codeController.clear();
                              _reloadCaptchaImage();
                            },
                      child: Image.memory(
                        width: double.infinity,
                        base64Decode(_imageData!.split(',').last),
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, _) => const Text('图片解码失败'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    child: TextField(
                      controller: _codeController,
                      autofocus: true,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: '请输入验证码',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: _isSubmitting ? null : (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _cancel,
                        child: Text('取消',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline)),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: (_imageData == null || _isSubmitting)
                            ? null
                            : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('提交'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/resources_item.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'captcha_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _SourceEpisodeMode { matched, all }

class VideoSourceDrawers extends ConsumerStatefulWidget {
  final Function(String url)? onVideoUrlSelected;
  final VideoSourceNotifier videoSourceNotifier;
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
    required this.videoSourceNotifier,
    required this.subjectName,
  });

  @override
  ConsumerState<VideoSourceDrawers> createState() => _VideoSourceDrawersState();
}

class _VideoSourceDrawersState extends ConsumerState<VideoSourceDrawers> {
  static const double _minSheetSize = 0.3;
  static const double _initialSheetSize = 0.52;
  static const double _maxSheetSize = 0.95;
  static const String _allLinesValue = '__all_lines__';

  final logger = LiggLogger();
  _SourceEpisodeMode _sourceEpisodeMode = _SourceEpisodeMode.matched;
  String? _selectedLineName;
  bool _sortDescending = false;
  final _searchController = TextEditingController();
  final Map<String, TextEditingController> _siteSearchControllers = {};
  int? _drawerSelectedWebsiteIndex;
  bool _followInitialAutoSelection = true;
  bool _sourceControlsCollapsed = false;
  late final ScrollController _fallbackScrollController;

  ScrollController get _scrollController =>
      widget.scrollController ?? _fallbackScrollController;

  @override
  void initState() {
    super.initState();
    _fallbackScrollController = ScrollController();
    _scrollController.addListener(_handleSourceListScroll);
    _searchController.text = widget.subjectName;
  }

  void _handleSourceListScroll() {
    final shouldCollapse = _scrollController.hasClients &&
        _scrollController.offset > 8 &&
        !_sourceControlsCollapsed;
    final shouldExpand = _scrollController.hasClients &&
        _scrollController.offset <= 8 &&
        _sourceControlsCollapsed;
    if (!shouldCollapse && !shouldExpand) return;
    setState(() {
      _sourceControlsCollapsed = shouldCollapse;
    });
  }

  void _setSelectedWebsite(int index) {
    _followInitialAutoSelection = false;
    _drawerSelectedWebsiteIndex = index;
    widget.videoSourceNotifier.setSelectedWebsiteIndex(index);
    setState(() {
      _sourceEpisodeMode = _SourceEpisodeMode.matched;
      _selectedLineName = null;
      _sortDescending = false;
    });
  }

  void _performSearch() {
    String searchQuery = _searchController.text;
    if (searchQuery.isNotEmpty) {
      _disposeSiteSearchControllers();
      final preserveCurrentPlayback =
          widget.videoSourceNotifier.videoUrl.isNotEmpty;
      widget.videoSourceNotifier.setSelectedWebsiteIndex(0);
      _followInitialAutoSelection = true;
      _drawerSelectedWebsiteIndex = 0;
      setState(() {
        _sourceEpisodeMode = _SourceEpisodeMode.matched;
        _selectedLineName = null;
        _sortDescending = false;
      });
      widget.videoSourceNotifier.initResources(
        searchQuery,
        preserveCurrentPlayback: preserveCurrentPlayback,
      );
    }
  }

  TextEditingController _siteSearchControllerFor(ResourcesItem resource) {
    return _siteSearchControllers.putIfAbsent(
      resource.websiteName,
      () => TextEditingController(text: widget.videoSourceNotifier.keyword),
    );
  }

  void _disposeSiteSearchControllers() {
    for (final controller in _siteSearchControllers.values) {
      controller.dispose();
    }
    _siteSearchControllers.clear();
  }

  void _retrySiteSearch(
    ResourcesItem resource,
    TextEditingController controller,
  ) {
    final keyword = controller.text.trim();
    if (keyword.isEmpty) return;
    widget.videoSourceNotifier.retryResources(
      resource.websiteName,
      keyword: keyword,
    );
  }

  int _getDrawerSelectedIndex(List<ResourcesItem> dataSource) {
    final controller = widget.videoSourceNotifier;
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
    _scrollController.removeListener(_handleSourceListScroll);
    if (widget.scrollController == null) {
      _fallbackScrollController.dispose();
    }
    _disposeSiteSearchControllers();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBottomSheet) {
      return Material(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 20, 16, 16 + MediaQuery.of(context).padding.bottom),
          child: _buildDrawerContent(includeDragHandle: true),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: LayoutConstant.playContentWidth,
        height: MediaQuery.of(context).size.height,
        child: Container(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top, left: 16, right: 16),
          color: Theme.of(context).cardColor,
          child: _buildDrawerContent(),
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

  Widget _buildDrawerContent({bool includeDragHandle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (includeDragHandle) _buildDragHandle(context),
        buildHeader(),
        _manualSearch(),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final sourceState = ref.watch(
              videoSourceProvider.select(
                (state) => (
                  videoResources: state.videoResources,
                  selectedWebsiteIndex: state.selectedWebsiteIndex,
                  webSiteTitle: state.webSiteTitle,
                ),
              ),
            );
            if (sourceState.videoResources.isEmpty) {
              return const SizedBox.shrink();
            }
            return _buildWebsiteSelector(
              dataSource: sourceState.videoResources,
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final sourceState = ref.watch(
                videoSourceProvider.select(
                  (state) => (
                    videoResources: state.videoResources,
                    currentEpisodeIndex: state.currentEpisodeIndex,
                    selectedWebsiteIndex: state.selectedWebsiteIndex,
                    webSiteTitle: state.webSiteTitle,
                    videoUrl: state.videoUrl,
                  ),
                ),
              );
              if (sourceState.videoResources.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildVideoSource(
                dataSource: sourceState.videoResources,
                selectedIndex: _getDrawerSelectedIndex(
                  sourceState.videoResources,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 标题行
  Widget buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          l10n.videoSource,
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
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Text(
            l10n.manualSearch,
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
                hintText: l10n.manualSearchResource,
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
    final videoSourceController = widget.videoSourceNotifier;
    if (selectedIndex >= dataSource.length) {
      return const SizedBox.shrink();
    }

    final selectedResource = dataSource[selectedIndex];
    final l10n = AppLocalizations.of(context);
    final episodeResources = selectedResource.episodeResources;

    if (selectedResource.needsCaptcha) {
      return CaptchaView(
        key: ValueKey(selectedResource.websiteName),
        resource: selectedResource,
        dataSourceController: widget.videoSourceNotifier,
        subjectName: widget.subjectName,
        isBottomSheet: widget.isBottomSheet,
      );
    }

    if (selectedResource.isLoading) {
      return _buildResourceStatusView(
        icon: const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        title: l10n.fetchingResource(selectedResource.websiteName),
        message: l10n.reSearchingResource,
      );
    }

    if (selectedResource.errorMessage != null) {
      return _buildResourceStatusView(
        icon: Icon(
          Icons.error_outline,
          size: 44,
          color: Theme.of(context).colorScheme.error,
        ),
        title: l10n.resourceRequestFailed(selectedResource.websiteName),
        message: selectedResource.errorMessage!,
        action: ElevatedButton(
          onPressed: () => videoSourceController
              .retryResources(selectedResource.websiteName),
          child: Text(l10n.retry),
        ),
      );
    }

    if (episodeResources.isEmpty) {
      final siteSearchController = _siteSearchControllerFor(selectedResource);
      return _buildResourceStatusView(
        icon: Icon(
          Icons.search_off_rounded,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: l10n.resourceNotFoundForSite(selectedResource.websiteName),
        message: l10n.noPlayableSourceHint,
        action: _buildSiteSearchAction(
          controller: siteSearchController,
          onSearch: () =>
              _retrySiteSearch(selectedResource, siteSearchController),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: _sourceControlsCollapsed
                ? const SizedBox.shrink()
                : _buildSourceControls(
                    lineNames: lineNames,
                    selectedLineName: selectedLineName,
                  ),
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
                    sortDescending: _sortDescending,
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
      final lineName = _normalizedLineName(item.lineNames);
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
      return _normalizedLineName(item.lineNames) == lineName;
    }).toList(growable: false);
  }

  String _normalizedLineName(String lineName) {
    final trimmed = lineName.trim();
    return trimmed.isEmpty ? AppLocalizations.of(context).unnamedLine : trimmed;
  }

  Widget _buildSourceControls({
    required List<String> lineNames,
    required String? selectedLineName,
  }) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: _buildLineDropdown(
              lineNames: lineNames,
              selectedLineName: selectedLineName,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _sortDescending = !_sortDescending;
              });
            },
            icon: Icon(
              _sortDescending ? Icons.south_rounded : Icons.north_rounded,
              size: 18,
            ),
            label: Text(_sortDescending ? l10n.descending : l10n.ascending),
          ),
        ],
      ),
    );
  }

  Widget _buildLineDropdown({
    required List<String> lineNames,
    required String? selectedLineName,
  }) {
    final l10n = AppLocalizations.of(context);
    final value = selectedLineName ?? _allLinesValue;
    final items = [_allLinesValue, ...lineNames];
    return DropDownMenu<String>(
      items: items,
      selectedItem: value,
      tooltip: l10n.lineFilter,
      offset: const Offset(0, 44),
      itemBuilder: (context, item, isSelected) {
        final label = item == _allLinesValue ? l10n.allLines : item;
        return SizedBox(
          width: 180,
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_rounded : Icons.account_tree_outlined,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
      buttonBuilder: (context, selectedItem) {
        final label = selectedItem == null || selectedItem == _allLinesValue
            ? l10n.allLines
            : selectedItem;
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down_rounded),
            ],
          ),
        );
      },
      onSelected: (value) {
        setState(() {
          _selectedLineName = value == _allLinesValue ? null : value;
        });
      },
    );
  }

  Widget _buildEpisodeModeSelector({
    required int matchedCount,
    required int allCount,
  }) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_SourceEpisodeMode>(
        segments: [
          ButtonSegment(
            value: _SourceEpisodeMode.matched,
            icon: const Icon(Icons.rule_rounded, size: 18),
            label: Text(l10n.currentEpisodeCount(matchedCount)),
          ),
          ButtonSegment(
            value: _SourceEpisodeMode.all,
            icon: const Icon(Icons.format_list_numbered_rounded, size: 18),
            label: Text(l10n.allEpisodesCount(allCount)),
          ),
        ],
        selected: {_sourceEpisodeMode},
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
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
    final l10n = AppLocalizations.of(context);
    if (matchedResources.isEmpty) {
      return _buildResourceStatusView(
        icon: Icon(
          Icons.playlist_remove_rounded,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: l10n.noPlayableSourceForEpisode,
        message: excludedEpisodesCount > 0
            ? l10n.episodeNotInResultsHint
            : l10n.episodeNoSourceHint,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: matchedResources.length,
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
    required bool sortDescending,
  }) {
    final l10n = AppLocalizations.of(context);
    final expandedItems = episodeResources.expand((item) {
      return item.episodes.map((ep) => (resource: item, episode: ep));
    }).toList(growable: false);
    expandedItems.sort((a, b) {
      final sortCompare =
          a.episode.episodeSort.compareTo(b.episode.episodeSort);
      if (sortCompare != 0) {
        return sortDescending ? -sortCompare : sortCompare;
      }
      final lineCompare = a.resource.lineNames.compareTo(b.resource.lineNames);
      if (lineCompare != 0) {
        return lineCompare;
      }
      return a.resource.subjectsTitle.compareTo(b.resource.subjectsTitle);
    });

    if (expandedItems.isEmpty) {
      return _buildResourceStatusView(
        icon: Icon(
          Icons.search_off_rounded,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: l10n.noSelectableEpisodes,
        message: l10n.siteNoEpisodes,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: expandedItems.length,
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

  Widget _buildSiteSearchAction({
    required TextEditingController controller,
    required VoidCallback onSearch,
  }) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: l10n.manualSearchResource,
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: controller.text.trim().isEmpty ? null : onSearch,
            child: Text(l10n.searchAgain),
          ),
        ],
      ),
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
    final videoUrl = widget.videoSourceNotifier.videoUrl;
    final isSelected = resolveSourceUrl(baseUrl, episode.like) == videoUrl;

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
              final videoUrl = resolveSourceUrl(baseUrl, episode.like);
              widget.videoSourceNotifier.bindManualSourceForCurrentEpisode(
                websiteName: websiteName,
                websiteIcon: websiteIcon,
                resourceTitle: item.subjectsTitle,
                lineName: item.lineNames,
                videoUrl: videoUrl,
              );
              widget.onVideoUrlSelected?.call(videoUrl);
            } catch (e) {
              logger.e('获取视频源失败', error: e);
              final l10n = AppLocalizations.of(context);
              NotificationToast.show(
                l10n.videoSourceLoadFailed(e.toString()),
                title: l10n.error,
              );
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
                                  ' ${AppLocalizations.of(context).episodeNumber(episode.episodeSort.toString().padLeft(2, '0'))}',
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
                      AppLocalizations.of(context).lineLabel('').trimRight(),
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
                    Text(AppLocalizations.of(context).matchLabel),
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

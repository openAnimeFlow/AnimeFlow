import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/logger/app_log.dart';
import 'package:anime_flow/core/utils/source_url.dart';
import 'package:anime_flow/core/video_source/domain/captcha_session.dart';
import 'package:anime_flow/core/video_source/domain/episode_source_matcher.dart';
import 'package:anime_flow/core/video_source/domain/selected_video_source.dart';
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/resources_item.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';

import 'captcha_view.dart';

enum _SourceEpisodeMode { matched, all }

typedef VideoSourceSelection = ({
  ResourcesItem website,
  EpisodeResourcesItem line,
  Episode episode,
  String url,
});

/// 展示调用方提供的资源列表，并将搜索、重试和选源操作交给调用方。
class VideoSourceDialog extends StatefulWidget {
  const VideoSourceDialog({
    super.key,
    required this.subjectName,
    required this.resources,
    required this.onSearch,
    required this.onRetry,
    required this.onSourceSelected,
    this.searchKeyword = '',
    this.initialSearchDraft,
    this.selectedWebsiteIndex = 0,
    this.selectedSource,
    this.episodeNumber,
    this.onSearchDraftChanged,
    this.onWebsiteSelected,
    this.createCaptchaSession,
    this.onCaptchaVerified,
    this.keyboardInsetHandled = false,
    this.scrollController,
    this.closeOnSelection = true,
  });

  final String subjectName;
  final List<ResourcesItem> resources;
  final String searchKeyword;
  final String? initialSearchDraft;
  final int selectedWebsiteIndex;
  final SelectedVideoSource? selectedSource;

  /// 省略集数时直接展示全部剧集。
  final num? episodeNumber;
  final ValueChanged<String> onSearch;
  final void Function(String websiteName, {String? keyword}) onRetry;
  final ValueChanged<VideoSourceSelection> onSourceSelected;
  final ValueChanged<String>? onSearchDraftChanged;
  final ValueChanged<int>? onWebsiteSelected;
  final CaptchaSession Function()? createCaptchaSession;
  final ValueChanged<String>? onCaptchaVerified;
  final bool keyboardInsetHandled;
  final ScrollController? scrollController;

  /// 下载等场景可保留弹窗，继续展示解析结果。
  final bool closeOnSelection;

  @override
  State<VideoSourceDialog> createState() => _VideoSourceDialogState();
}

class _VideoSourceDialogState extends State<VideoSourceDialog> {
  static const String _allLinesValue = '__all_lines__';

  _SourceEpisodeMode _sourceEpisodeMode = _SourceEpisodeMode.matched;
  String? _selectedLineName;
  bool _sortDescending = false;
  final _searchController = TextEditingController();
  final Map<String, TextEditingController> _siteSearchControllers = {};
  int? _selectedWebsiteIndex;

  /// 未手动切换站点时优先展示调用方选中的资源。
  bool _followAutoSelectedWebsite = true;
  bool _sourceControlsCollapsed = false;
  late final ScrollController _fallbackScrollController;

  ScrollController get _scrollController =>
      widget.scrollController ?? _fallbackScrollController;

  @override
  void initState() {
    super.initState();
    _fallbackScrollController = ScrollController();
    _scrollController.addListener(_handleSourceListScroll);
    _searchController.text = widget.initialSearchDraft ?? widget.subjectName;
  }

  @override
  void didUpdateWidget(VideoSourceDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      (oldWidget.scrollController ?? _fallbackScrollController)
          .removeListener(_handleSourceListScroll);
      _scrollController.addListener(_handleSourceListScroll);
    }
    if (oldWidget.subjectName != widget.subjectName) {
      final subjectName = widget.subjectName;
      _searchController.text = subjectName;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            widget.subjectName == subjectName &&
            _searchController.text == subjectName) {
          widget.onSearchDraftChanged?.call(subjectName);
        }
      });
    }
  }

  void _handleSourceListScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final offset = position.pixels - position.minScrollExtent;
    final collapsed = _sourceControlsCollapsed ? offset > 0 : offset > 8;
    if (collapsed == _sourceControlsCollapsed) return;
    setState(() => _sourceControlsCollapsed = collapsed);
  }

  void _setSelectedWebsite(int index) {
    _followAutoSelectedWebsite = false;
    _selectedWebsiteIndex = index;
    widget.onWebsiteSelected?.call(index);
    setState(_resetSourceViewState);
  }

  void _restoreDefaultSearchKeyword() {
    final keyword = widget.subjectName;
    _searchController.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    widget.onSearchDraftChanged?.call(keyword);
  }

  void _performSearch() {
    final searchQuery = _searchController.text;
    if (searchQuery.isEmpty) return;
    _disposeSiteSearchControllers();
    widget.onWebsiteSelected?.call(0);
    _followAutoSelectedWebsite = true;
    _selectedWebsiteIndex = 0;
    setState(_resetSourceViewState);
    widget.onSearch(searchQuery);
  }

  /// 切换数据源 / 重新搜索后，线路、集数模式与排序都回到默认值。
  void _resetSourceViewState() {
    _sourceControlsCollapsed = false;
    _sourceEpisodeMode = _SourceEpisodeMode.matched;
    _selectedLineName = null;
    _sortDescending = false;
  }

  TextEditingController _siteSearchControllerFor(ResourcesItem resource) {
    return _siteSearchControllers.putIfAbsent(
      resource.websiteName,
      () => TextEditingController(text: widget.searchKeyword),
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
    widget.onRetry(
      resource.websiteName,
      keyword: keyword,
    );
  }

  /// 当前应选中的数据源下标。
  ///
  /// 调用方选定站点前跟随建议的下标，之后保持本地选择。
  int _resolveSelectedWebsiteIndex(List<ResourcesItem> dataSource) {
    final websiteName = widget.selectedSource?.websiteName ?? '';
    final matchedIndex = websiteName.isEmpty
        ? -1
        : dataSource.indexWhere(
            (resource) => resource.websiteName == websiteName,
          );
    final suggestedIndex = widget.selectedWebsiteIndex;
    final validIndex = suggestedIndex >= 0 && suggestedIndex < dataSource.length
        ? suggestedIndex
        : 0;
    final autoIndex = matchedIndex >= 0 ? matchedIndex : validIndex;

    if (_followAutoSelectedWebsite) {
      _selectedWebsiteIndex = autoIndex;
      if (websiteName.isNotEmpty) {
        _followAutoSelectedWebsite = false;
      }
      return _selectedWebsiteIndex!;
    }

    final current = _selectedWebsiteIndex;
    if (current == null || current >= dataSource.length) {
      _selectedWebsiteIndex = autoIndex;
    }
    return _selectedWebsiteIndex!;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleSourceListScroll);
    _fallbackScrollController.dispose();
    _disposeSiteSearchControllers();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 +
            (widget.keyboardInsetHandled
                ? 0
                : MediaQuery.viewInsetsOf(context).bottom),
      ),
      child: _buildDrawerContent(),
    );
  }

  Widget _buildDrawerContent() {
    final l10n = AppLocalizations.of(context);
    final resources = widget.resources;
    final selectedIndex =
        resources.isEmpty ? null : _resolveSelectedWebsiteIndex(resources);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(l10n),
        _buildManualSearch(l10n),
        const SizedBox(height: 16),
        if (selectedIndex != null) ...[
          _buildWebsiteSelector(
            dataSource: resources,
            selectedIndex: selectedIndex,
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildVideoSource(resources[selectedIndex])),
        ],
      ],
    );
  }

  /// 标题行
  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        _sectionTitle(l10n.videoSource),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  /// 抽屉内的小节标题样式。
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _buildManualSearch(AppLocalizations l10n) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          _sectionTitle(l10n.manualSearch),
          const SizedBox(width: 5),
          Expanded(
            child: Material(
              child: TextField(
                controller: _searchController,
                onChanged: widget.onSearchDraftChanged,
                decoration: InputDecoration(
                  hintText: l10n.manualSearchResource,
                  suffixIcon: IconButton(
                    tooltip: l10n.restoreDefaultSearchKeyword,
                    onPressed: _restoreDefaultSearchKeyword,
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 数据源选择器
  Widget _buildWebsiteSelector({
    required List<ResourcesItem> dataSource,
    required int selectedIndex,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Icon(Icons.public, size: 24, color: colorScheme.onSurface),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemCount: dataSource.length,
              itemBuilder: (context, index) {
                final data = dataSource[index];
                return GestureDetector(
                  onTap: () => _setSelectedWebsite(index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedIndex == index
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (data.websiteIcon.trim().isEmpty)
                          const Icon(Icons.public, size: 24)
                        else
                          ClipOval(
                            child: AnimationNetworkImage(
                              width: 24,
                              height: 24,
                              url: data.websiteIcon,
                            ),
                          ),
                        _buildWebsiteStatusIcon(data, colorScheme),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 数据源角标：加载中 / 需要验证 / 请求失败 / 已有资源。
  Widget _buildWebsiteStatusIcon(ResourcesItem data, ColorScheme colorScheme) {
    if (data.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: colorScheme.primary),
        ),
      );
    }
    if (data.needsCaptcha) {
      return const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Icon(Icons.shield_outlined, size: 14, color: Colors.blue),
      );
    }
    if (data.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(Icons.error_outline, size: 14, color: colorScheme.error),
      );
    }
    if (data.episodeResources.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(Icons.check_circle_outline,
          size: 14, color: colorScheme.primary),
    );
  }

  Widget _buildVideoSource(ResourcesItem selectedResource) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final episodeResources = selectedResource.episodeResources;

    if (selectedResource.needsCaptcha) {
      final websiteName = selectedResource.websiteName;
      final retry = widget.onRetry;
      final onVerified = widget.onCaptchaVerified;
      return CaptchaView(
        key: ValueKey(websiteName),
        resource: selectedResource,
        subjectName: widget.subjectName,
        createSession: widget.createCaptchaSession,
        onVerified: onVerified == null
            ? () => retry(websiteName)
            : () => onVerified(websiteName),
        onRetry: () => retry(websiteName),
        keyboardInsetHandled: widget.keyboardInsetHandled,
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
        icon: Icon(Icons.error_outline, size: 44, color: colorScheme.error),
        title: l10n.resourceRequestFailed(selectedResource.websiteName),
        message: selectedResource.errorMessage!,
        action: ElevatedButton(
          onPressed: () => widget.onRetry(selectedResource.websiteName),
          child: Text(l10n.retry),
        ),
      );
    }

    if (episodeResources.isEmpty) {
      final siteSearchController = _siteSearchControllerFor(selectedResource);
      return _buildResourceStatusView(
        icon: Icon(Icons.search_off_rounded,
            size: 44, color: colorScheme.onSurfaceVariant),
        title: l10n.resourceNotFoundForSite(selectedResource.websiteName),
        message: l10n.noPlayableSourceHint,
        action: _buildSiteSearchAction(
          controller: siteSearchController,
          onSearch: () =>
              _retrySiteSearch(selectedResource, siteSearchController),
        ),
      );
    }
    final episodeNumber = widget.episodeNumber;
    final lineNames = _buildLineNames(episodeResources);
    final selectedLineName =
        lineNames.contains(_selectedLineName) ? _selectedLineName : null;
    final filteredEpisodeResources = _filterResourcesByLine(
      episodeResources,
      selectedLineName,
    );

    final matchedResources = [
      if (episodeNumber != null)
        for (final item in filteredEpisodeResources)
          if (EpisodeSourceMatcher.findEpisode(item.episodes, episodeNumber) !=
              null)
            item,
    ];
    final allCount = filteredEpisodeResources.fold<int>(
      0,
      (sum, item) => sum + item.episodes.length,
    );

    return Material(
      child: Column(
        children: [
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: _sourceControlsCollapsed ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: ExcludeSemantics(
                excluding: _sourceControlsCollapsed,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSourceControls(
                      lineNames: lineNames,
                      selectedLineName: selectedLineName,
                    ),
                    if (episodeNumber != null) ...[
                      const SizedBox(height: 8),
                      _buildEpisodeModeSelector(
                        matchedCount: matchedResources.length,
                        allCount: allCount,
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: episodeNumber == null ||
                    _sourceEpisodeMode == _SourceEpisodeMode.all
                ? _buildAllEpisodeSources(
                    episodeResources: filteredEpisodeResources,
                    selectedResource: selectedResource,
                    episodeNumber: episodeNumber,
                  )
                : _buildMatchedEpisodeSources(
                    matchedResources: matchedResources,
                    selectedResource: selectedResource,
                    episodeNumber: episodeNumber,
                    hasExcludedEpisodes: filteredEpisodeResources.any(
                      (item) => item.episodes.any((episode) =>
                          !EpisodeSourceMatcher.matchesEpisode(
                              episode, episodeNumber)),
                    ),
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
    final colorScheme = Theme.of(context).colorScheme;
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
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
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
            border: Border.all(color: colorScheme.outline),
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
    required num episodeNumber,
    required bool hasExcludedEpisodes,
  }) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    if (matchedResources.isEmpty) {
      return _buildResourceStatusView(
        icon: Icon(
          Icons.playlist_remove_rounded,
          size: 44,
          color: colorScheme.onSurfaceVariant,
        ),
        title: l10n.noPlayableSourceForEpisode,
        message: hasExcludedEpisodes
            ? l10n.episodeNotInResultsHint
            : l10n.episodeNoSourceHint,
      );
    }

    final selectedIndex = _resolveSelectedSourceIndex(
      length: matchedResources.length,
      baseUrl: selectedResource.baseUrl,
      episodeAt: (index) => _episodeOf(matchedResources[index], episodeNumber),
      itemAt: (index) => matchedResources[index],
    );

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: matchedResources.length,
      itemBuilder: (context, index) {
        final resourceItem = matchedResources[index];
        return _buildSource(
          _episodeOf(resourceItem, episodeNumber),
          resourceItem,
          website: selectedResource,
          isSelected: index == selectedIndex,
        );
      },
    );
  }

  Widget _buildAllEpisodeSources({
    required List<EpisodeResourcesItem> episodeResources,
    required ResourcesItem selectedResource,
    required num? episodeNumber,
  }) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final expandedItems = episodeResources.expand((item) {
      return item.episodes.map((ep) => (resource: item, episode: ep));
    }).toList(growable: false);
    expandedItems.sort((a, b) {
      final sortCompare =
          a.episode.episodeSort.compareTo(b.episode.episodeSort);
      if (sortCompare != 0) {
        return _sortDescending ? -sortCompare : sortCompare;
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
          color: colorScheme.onSurfaceVariant,
        ),
        title: l10n.noSelectableEpisodes,
        message: l10n.siteNoEpisodes,
      );
    }

    final selectedIndex = _resolveSelectedSourceIndex(
      length: expandedItems.length,
      baseUrl: selectedResource.baseUrl,
      episodeNumber: episodeNumber,
      episodeAt: (index) => expandedItems[index].episode,
      itemAt: (index) => expandedItems[index].resource,
    );

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: expandedItems.length,
      itemBuilder: (context, index) {
        final entry = expandedItems[index];
        return _buildSource(
          entry.episode,
          entry.resource,
          website: selectedResource,
          isSelected: index == selectedIndex,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
        },
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
            onChanged: (_) => setState(() {}),
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
    final colorScheme = Theme.of(context).colorScheme;
    final (Color color, Color containerColor) = ratio >= 0.9
        ? (colorScheme.primary, colorScheme.primaryContainer)
        : ratio >= 0.7
            ? (colorScheme.tertiary, colorScheme.tertiaryContainer)
            : ratio >= 0.5
                ? (colorScheme.secondary, colorScheme.secondaryContainer)
                : (colorScheme.error, colorScheme.errorContainer);

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

  /// 线路名与资源标题是否与已选资源一致。
  bool _isSameSourceMeta(
      EpisodeResourcesItem item, SelectedVideoSource source) {
    if (source.lineName.isNotEmpty && source.lineName != item.lineNames) {
      return false;
    }
    if (source.resourceTitle.isNotEmpty &&
        source.resourceTitle != item.subjectsTitle) {
      return false;
    }
    return true;
  }

  /// 资源项中对应集数的剧集（调用方已按集数过滤，取首个匹配项即可）。
  Episode _episodeOf(EpisodeResourcesItem item, num episodeNumber) {
    return EpisodeSourceMatcher.findEpisode(item.episodes, episodeNumber)!;
  }

  /// 计算已选资源在候选列表中的下标。
  int _resolveSelectedSourceIndex({
    required int length,
    required String baseUrl,
    required Episode Function(int index) episodeAt,
    required EpisodeResourcesItem Function(int index) itemAt,
    num? episodeNumber,
  }) {
    final source = widget.selectedSource;
    if (source == null || source.videoUrl.isEmpty) return -1;
    var fallbackIndex = -1;
    for (var index = 0; index < length; index++) {
      final episode = episodeAt(index);
      if (episodeNumber != null &&
          !EpisodeSourceMatcher.matchesEpisode(episode, episodeNumber)) {
        continue;
      }
      if (resolveSourceUrl(baseUrl, episode.like) != source.videoUrl) {
        continue;
      }
      if (fallbackIndex < 0) {
        fallbackIndex = index;
      }
      if (_isSameSourceMeta(itemAt(index), source)) {
        return index;
      }
    }
    return fallbackIndex;
  }

  Widget _buildSource(
    Episode episode,
    EpisodeResourcesItem item, {
    required ResourcesItem website,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(width: 2.5, color: colorScheme.primary)
            : null,
      ),
      child: Card.filled(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            try {
              final selection = (
                website: website,
                line: item,
                episode: episode,
                url: resolveSourceUrl(website.baseUrl, episode.like),
              );
              final onSourceSelected = widget.onSourceSelected;
              if (widget.closeOnSelection) Navigator.of(context).pop();
              onSourceSelected(selection);
            } catch (e) {
              logError('获取视频源失败', error: e);
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
                                  ' ${l10n.episodeNumber(episode.episodeSort.toString().padLeft(2, '0'))}',
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
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              l10n.lineLabel(item.lineNames).trimRight(),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.link,
                              size: 16, color: colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                    Text(l10n.matchLabel),
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

import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/features/play/presentation/widgets/loading_animation.dart';
import 'package:anime_flow/features/play/presentation/widgets/episode_load_more_error.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/features/play/domain/episodes_data.dart';

class EpisodesListView extends StatefulWidget {
  const EpisodesListView({
    super.key,
    required this.episodesAsync,
    required this.isGridView,
    required this.subjectCover,
    required this.isPlaying,
    required this.onEpisodeSelected,
    required this.onLoadMore,
    required this.onRetry,
    required this.onRetryLoadMore,
    this.onToggleWatched,
  });

  final AsyncValue<EpisodesData> episodesAsync;
  final bool isGridView;
  final String subjectCover;
  final bool isPlaying;
  final ValueChanged<EpisodeData> onEpisodeSelected;
  final ValueChanged<EpisodeData>? onToggleWatched;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final VoidCallback onRetryLoadMore;

  @override
  State<EpisodesListView> createState() => _EpisodesListViewState();
}

class _EpisodesListViewState extends State<EpisodesListView> {
  final controller = ScrollController();

  /// 上次滚动定位对应的 episodeId，避免 rebuild 重复触发滚动
  int? lastScrolledEpisodeId;

  /// 剧集列表每行固定高度
  static const double itemHeight = 76;

  /// 每行之间的间距（ListView.separated）
  static const double itemSpacing = 4;

  static const double _loadMoreFooterHeight = 44;
  static const double _loadMoreTriggerDistance = 80;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    controller.removeListener(_onScroll);
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EpisodesListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isGridView && !widget.isGridView) {
      lastScrolledEpisodeId = null;
    }
  }

  void _onScroll() {
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.pixels >=
        position.maxScrollExtent - _loadMoreTriggerDistance) {
      widget.onLoadMore();
    }
  }

  /// 将列表滚动到当前选集对应行（需在布局完成、`controller` 已 attach 后调用）。
  void _scrollListToSelectedEpisode(
    List<EpisodeData> episodes,
    int episodeId,
  ) {
    if (!mounted || widget.isGridView || !controller.hasClients) return;
    final index = episodes.indexWhere(
      (e) => e.id == episodeId,
    );
    if (index < 0) return;
    final maxExtent = controller.position.maxScrollExtent;
    final offset = (index * (itemHeight + itemSpacing)).clamp(0.0, maxExtent);
    controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return widget.episodesAsync.when(
      skipLoadingOnReload: true,
      loading: () => Column(
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(l10n.fetchingEpisodes),
        ],
      ),
      error: (error, _) => _buildLoadError(error),
      data: (episodesState) {
        final episodes = episodesState.episodes?.data ?? const <EpisodeData>[];
        final selectedEpisodeId = episodesState.episodeId;
        final itemCount =
            episodes.length + (episodesState.isLoadingMore ? 1 : 0);
        return Column(
          children: [
            if (episodes.isEmpty)
              Text(l10n.noEpisodeData)
            else if (widget.isGridView)
              _buildGridEpisodes(episodes, selectedEpisodeId, itemCount)
            else
              _buildListEpisodes(episodes, selectedEpisodeId, itemCount),
            if (episodesState.loadMoreError case final error?)
              EpisodeLoadMoreError(
                error: error,
                onRetry: widget.onRetryLoadMore,
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoadError(Object error) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).episodeLoadFailed),
            const SizedBox(height: 8),
            Text(
              '$error',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListEpisodes(
    List<EpisodeData> episodes,
    int selectedEpisodeId,
    int itemCount,
  ) {
    if (lastScrolledEpisodeId != selectedEpisodeId) {
      lastScrolledEpisodeId = selectedEpisodeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollListToSelectedEpisode(episodes, selectedEpisodeId);
      });
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.8),
      ),
      child: ListView.separated(
        controller: controller,
        itemCount: itemCount,
        padding: EdgeInsets.zero,
        itemExtentBuilder: (index, _) {
          // 偶数索引是列表项，奇数索引是分隔项。
          if (index.isOdd) return itemSpacing;
          return index ~/ 2 < episodes.length
              ? itemHeight
              : _loadMoreFooterHeight;
        },
        itemBuilder: (context, index) {
          if (index >= episodes.length) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final episode = episodes[index];
          return _buildEpisodeListTile(
            episode,
            isSelected: selectedEpisodeId == episode.id,
          );
        },
        separatorBuilder: (context, index) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildEpisodeListTile(
    EpisodeData episode, {
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final watched = episode.watched == true;
    final cardColor = theme.cardTheme.color ??
        (theme.useMaterial3 ? colors.surfaceContainerLow : theme.cardColor);
    final shape = RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      side: watched
          ? BorderSide(color: colors.secondaryContainer, width: 2)
          : BorderSide.none,
    );

    final coverUrl = episode.cover;
    final cover = AspectRatio(
      aspectRatio: 5 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: colors.surfaceContainerHighest,
            child: AnimationNetworkImage(
              url: coverUrl != null && coverUrl.isNotEmpty
                  ? coverUrl
                  : widget.subjectCover,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Colors.black54, Colors.transparent],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Text(
                episode.sort.toString().padLeft(2, '0'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
    final details = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.nameCN.isEmpty ? episode.name : episode.nameCN,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  spacing: 8,
                  children: [
                    if (episode.type != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          episodesTypeLabels[episode.type] ?? '',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    if (episode.airdate.isNotEmpty)
                      Flexible(
                        child: Text(
                          episode.airdate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isSelected)
            LoadingAnimation(
              size: 35,
              isPlaying: widget.isPlaying,
            ),
        ],
      ),
    );

    return Material(
      color: watched ? colors.surfaceContainerHighest : cardColor,
      shape: shape,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      animationDuration: Duration.zero,
      child: Padding(
        padding: shape.dimensions,
        child: InkWell(
          onTap: () => widget.onEpisodeSelected(episode),
          onLongPress: widget.onToggleWatched == null
              ? null
              : () => widget.onToggleWatched!(episode),
          child: Row(
            spacing: 5,
            children: [cover, Expanded(child: details)],
          ),
        ),
      ),
    );
  }

  Widget _buildGridEpisodes(
    List<EpisodeData> episodes,
    int selectedEpisodeId,
    int itemCount,
  ) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.8),
      ),
      child: GridView.builder(
        controller: controller,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= episodes.length) {
            return const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final colorScheme = Theme.of(context).colorScheme;
          final episode = episodes[index];
          final isSelected = selectedEpisodeId == episode.id;
          return Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => widget.onEpisodeSelected(episode),
              child: DecoratedBox(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: episode.watched == true
                        ? colorScheme.surfaceContainerHighest
                        : null,
                    border: episode.watched == true
                        ? Border.all(
                            color: colorScheme.secondaryContainer,
                            width: 2,
                          )
                        : null),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${episode.sort}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isSelected)
                      LoadingAnimation(
                        size: 35,
                        isPlaying: widget.isPlaying,
                      )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

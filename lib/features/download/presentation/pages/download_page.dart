import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadPage extends ConsumerWidget {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(downloadControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloadsTitle),
      ),
      body: state.records.isEmpty
          ? Center(child: Text(l10n.downloadTasksEmpty))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _DownloadRecordCard(record: state.records[index]);
              },
            ),
    );
  }
}

class _DownloadRecordCard extends ConsumerStatefulWidget {
  const _DownloadRecordCard({required this.record});

  final DownloadRecord record;

  @override
  ConsumerState<_DownloadRecordCard> createState() =>
      _DownloadRecordCardState();
}

class _DownloadRecordCardState extends ConsumerState<_DownloadRecordCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = _hasActiveDownload(widget.record);
  }

  @override
  void didUpdateWidget(covariant _DownloadRecordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isExpanded &&
        !_hasActiveDownload(oldWidget.record) &&
        _hasActiveDownload(widget.record)) {
      _isExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final record = widget.record;
    final episodes = record.episodes.values.toList()
      ..sort((a, b) => a.episodeSort.compareTo(b.episodeSort));
    final completed = episodes
        .where((episode) => episode.status == DownloadStatus.completed)
        .length;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => setState(() {
                _isExpanded = !_isExpanded;
              }),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AnimationNetworkImage(
                      url: record.subjectCover,
                      width: 52,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.sourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.downloadTaskProgress(completed, episodes.length),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: _isExpanded
                        ? l10n.collapseDownloadEpisodes
                        : l10n.expandDownloadEpisodes,
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    onPressed: () => setState(() {
                      _isExpanded = !_isExpanded;
                    }),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? Column(
                      children: [
                        const SizedBox(height: 8),
                        for (final episode in episodes) ...[
                          const Divider(height: 16),
                          _DownloadEpisodeTile(
                            record: record,
                            episode: episode,
                          ),
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveDownload(DownloadRecord record) {
    return record.episodes.values.any((episode) {
      return episode.status == DownloadStatus.pending ||
          episode.status == DownloadStatus.resolving ||
          episode.status == DownloadStatus.downloading;
    });
  }
}

class _DownloadEpisodeTile extends ConsumerWidget {
  const _DownloadEpisodeTile({
    required this.record,
    required this.episode,
  });

  final DownloadRecord record;
  final DownloadEpisode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final progress = episode.progressPercent.clamp(0, 100) / 100;
    final canPause = episode.status == DownloadStatus.downloading ||
        episode.status == DownloadStatus.resolving ||
        episode.status == DownloadStatus.pending;
    final canRetry = episode.status == DownloadStatus.paused ||
        episode.status == DownloadStatus.failed;
    final localMediaPath =
        ref.watch(downloadManagerProvider).getLocalMediaPath(episode);
    final canPlay = localMediaPath != null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _episodeTitle(l10n, episode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (episode.status != DownloadStatus.completed &&
                  episode.status != DownloadStatus.failed) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress == 0 ? null : progress,
                  minHeight: 4,
                ),
              ],
              const SizedBox(height: 6),
              Text(
                _statusText(l10n, episode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: l10n.play,
          icon: const Icon(Icons.play_arrow_rounded),
          onPressed: canPlay
              ? () => _playOfflineEpisode(
                    context,
                    record: record,
                    episode: episode,
                    localMediaPath: localMediaPath,
                  )
              : null,
        ),
        if (canPause)
          IconButton(
            tooltip: l10n.pause,
            icon: const Icon(Icons.pause_rounded),
            onPressed: () {
              ref.read(downloadControllerProvider.notifier).pause(
                    record.key,
                    episode.episodeUrl,
                  );
            },
          ),
        if (canRetry)
          IconButton(
            tooltip: l10n.retry,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(downloadControllerProvider.notifier).resume(
                    StartDownloadParams(
                      subjectId: record.subjectId,
                      subjectName: record.subjectName,
                      subjectCover: record.subjectCover,
                      sourceName: record.sourceName,
                      sourceBaseUrl: record.sourceBaseUrl,
                      lineIndex: episode.lineIndex,
                      episodeUrl: episode.episodeUrl,
                      episodeTitle: episode.episodeTitle,
                      bangumiEpisodeId: episode.bangumiEpisodeId,
                      episodeSort: episode.episodeSort,
                      episodeIndex: episode.episodeIndex,
                      networkMediaUrl: episode.networkMediaUrl,
                    ),
                  );
            },
          ),
        IconButton(
          tooltip: l10n.deleteDownloadTask,
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => _confirmDeleteEpisode(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteEpisode(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final episodeTitle = _episodeTitle(l10n, episode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteDownloadTask),
          content: Text(l10n.deleteDownloadTaskConfirmation(episodeTitle)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(downloadControllerProvider.notifier).deleteEpisode(
          record.key,
          episode.episodeUrl,
        );
  }

  void _playOfflineEpisode(
    BuildContext context, {
    required DownloadRecord record,
    required DownloadEpisode episode,
    required String localMediaPath,
  }) {
    final completedEpisodes = record.episodes.values
        .where((item) => item.status == DownloadStatus.completed)
        .toList();
    PlayRoute.fromExtra(
      PlayRouteExtra(
        playExtra: PlayExtra(
          subjectId: record.subjectId,
          subjectName: record.subjectName,
          subjectCover: record.subjectCover,
          subjectAliases: const [],
        ),
        continueEpisodeId:
            episode.bangumiEpisodeId > 0 ? episode.bangumiEpisodeId : null,
        isOfflineMode: true,
        offlineMediaPath: localMediaPath,
        offlineDanmakuPath: episode.localDanmakuPath.trim().isEmpty
            ? null
            : episode.localDanmakuPath,
        offlineEpisodeUrl: episode.episodeUrl,
        offlineEpisodes: completedEpisodes,
      ),
    ).push(context);
  }

  String _episodeTitle(AppLocalizations l10n, DownloadEpisode episode) {
    final name = episode.episodeTitle.trim();
    final episodeNumber = l10n.episodeNumber(_episodeNumberLabel(episode));
    if (name.isNotEmpty) {
      return '$episodeNumber · $name';
    }
    return episodeNumber;
  }

  Object _episodeNumberLabel(DownloadEpisode episode) {
    if (episode.episodeSort % 1 == 0) {
      return episode.episodeSort.toInt();
    }
    return episode.episodeSort;
  }

  String _statusText(AppLocalizations l10n, DownloadEpisode episode) {
    final status = switch (episode.status) {
      DownloadStatus.pending => l10n.downloadQueued,
      DownloadStatus.resolving => l10n.downloadResolving,
      DownloadStatus.downloading => l10n.downloadDownloadingStatus,
      DownloadStatus.completed => l10n.downloadCompletedStatus,
      DownloadStatus.failed => l10n.downloadFailedStatus,
      DownloadStatus.paused => l10n.downloadPausedStatus,
      _ => l10n.downloadQueued,
    };
    if (episode.status == DownloadStatus.completed) {
      final details = <String>[];
      if (episode.totalBytes > 0) {
        details.add(Utils.formatBytes(episode.totalBytes));
      }
      details.add(
        episode.danmakuDownloaded
            ? l10n.downloadWithDanmaku
            : l10n.downloadWithoutDanmaku,
      );
      return details.isEmpty ? status : '$status - ${details.join(' - ')}';
    }
    if (episode.status == DownloadStatus.failed) {
      final detail = episode.errorMessage.trim();
      return detail.isEmpty ? status : '$status - $detail';
    }
    final progress =
        '${episode.progressPercent.clamp(0, 100).toStringAsFixed(1)}%';
    return '$status - $progress';
  }
}

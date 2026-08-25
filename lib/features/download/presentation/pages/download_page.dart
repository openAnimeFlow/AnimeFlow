import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
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

class _DownloadRecordCard extends ConsumerWidget {
  const _DownloadRecordCard({required this.record});

  final DownloadRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
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
            Row(
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
              ],
            ),
            const SizedBox(height: 8),
            for (final episode in episodes) ...[
              const Divider(height: 16),
              _DownloadEpisodeTile(
                record: record,
                episode: episode,
              ),
            ],
          ],
        ),
      ),
    );
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
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: episode.status == DownloadStatus.completed
                    ? 1
                    : progress == 0
                        ? null
                        : progress,
                minHeight: 4,
              ),
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
          onPressed: () {
            ref.read(downloadControllerProvider.notifier).deleteEpisode(
                  record.key,
                  episode.episodeUrl,
                );
          },
        ),
      ],
    );
  }

  String _episodeTitle(AppLocalizations l10n, DownloadEpisode episode) {
    final name = episode.episodeTitle.trim();
    if (name.isNotEmpty) {
      return l10n.playEpisode(name);
    }
    return l10n.playEpisode(episode.episodeIndex);
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
    final progress =
        '${episode.progressPercent.clamp(0, 100).toStringAsFixed(1)}%';
    final detail = episode.errorMessage.trim();
    if (detail.isNotEmpty && episode.status == DownloadStatus.failed) {
      return '$status - $detail';
    }
    return '$status - $progress';
  }
}

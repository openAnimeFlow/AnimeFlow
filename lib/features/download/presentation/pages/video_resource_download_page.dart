import 'dart:math' as math;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/features/download/presentation/widgets/download_resource_dialog.dart';
import 'package:anime_flow/features/download/domain/download_status.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class VideoResourceDownloadPage extends StatelessWidget {
  const VideoResourceDownloadPage({
    super.key,
    required this.subjectName,
    required this.subjectCover,
    required this.episodes,
  });

  final String subjectName;
  final String subjectCover;
  final List<EpisodeData> episodes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadResources)),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const maxPageWidth = 1500.0;
            final horizontalPadding =
                16.0 + math.max(0.0, (constraints.maxWidth - maxPageWidth) / 2);
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  sliver: SliverMainAxisGroup(slivers: [
                    SliverToBoxAdapter(
                      child: Card(
                        margin: const EdgeInsets.only(top: 16, bottom: 24),
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subjectName,
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.episodeCount(episodes.length),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (episodes.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            l10n.noEpisodeData,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            l10n.episodeList,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 24),
                        sliver: SliverList.separated(
                          itemCount: episodes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) => _EpisodeCard(
                            episode: episodes[index],
                            subjectName: subjectName,
                            subjectCover: subjectCover,
                          ),
                        ),
                      ),
                    ],
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({
    required this.episode,
    required this.subjectName,
    required this.subjectCover,
  });

  final EpisodeData episode;
  final String subjectName;
  final String subjectCover;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final localizedName = episode.nameCN.trim();
    final name = localizedName.isEmpty ? episode.name.trim() : localizedName;
    final sort = episode.sort;
    final number = l10n.episodeNumber(sort % 1 == 0 ? sort.toInt() : sort);
    final duration = episode.duration.trim();
    final airdate = episode.airdate.trim();
    final cover = episode.cover?.trim() ?? '';
    final details = [
      if (name.isNotEmpty) number,
      if (duration.isNotEmpty) duration,
      if (airdate.isNotEmpty) airdate,
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (cover.isNotEmpty) ...[
              AnimationNetworkImage(
                url: cover,
                width: 88,
                height: 50,
                placeholderWidth: 88,
                placeholderHeight: 50,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? number : name,
                      style: theme.textTheme.titleSmall),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      details.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _EpisodeDownloadButton(
                subjectName: subjectName,
                subjectCover: subjectCover,
                episode: episode),
          ],
        ),
      ),
    );
  }
}

class _EpisodeDownloadButton extends ConsumerStatefulWidget {
  const _EpisodeDownloadButton(
      {required this.subjectName,
      required this.subjectCover,
      required this.episode});
  final String subjectName;
  final String subjectCover;
  final EpisodeData episode;

  @override
  ConsumerState<_EpisodeDownloadButton> createState() =>
      _EpisodeDownloadButtonState();
}

class _EpisodeDownloadButtonState
    extends ConsumerState<_EpisodeDownloadButton> {
  bool _opening = false;
  bool _updating = false;

  Future<void> _toggleDownload(String recordKey, String episodeUrl) async {
    if (_updating) return;
    final record = ref.read(downloadRepositoryProvider).getRecord(recordKey);
    final episode = record?.episodes[episodeUrl];
    if (record == null || episode == null) return;
    final controller = ref.read(downloadControllerProvider.notifier);
    setState(() => _updating = true);
    try {
      if (episode.status == DownloadStatus.paused) {
        await controller.resume(StartDownloadParams(
          subjectId: record.subjectId,
          subjectName: record.subjectName,
          subjectCover: record.subjectCover.trim().isEmpty
              ? widget.subjectCover
              : record.subjectCover,
          sourceName: record.sourceName,
          sourceBaseUrl: record.sourceBaseUrl,
          lineIndex: episode.lineIndex,
          episodeUrl: episode.episodeUrl,
          episodeTitle: episode.episodeTitle,
          bangumiEpisodeId: episode.bangumiEpisodeId,
          episodeSort: episode.episodeSort,
          episodeIndex: episode.episodeIndex,
          networkMediaUrl: episode.networkMediaUrl,
        ));
      } else if (DownloadStatus.isActive(episode.status)) {
        await controller.pause(recordKey, episodeUrl);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppLocalizations.of(context).error}: $error'),
        ));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _open() async {
    setState(() => _opening = true);
    try {
      await showDialog<bool>(
        context: context,
        builder: (_) => DownloadResourceDialog(
          subjectName: widget.subjectName,
          subjectCover: widget.subjectCover,
          episode: widget.episode,
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final download = ref.watch(downloadControllerProvider.select((state) {
      // 订阅不可变的进度快照，避免 DownloadEpisode 原地更新时漏掉重建。
      ({
        int? status,
        double progress,
        bool hasTotal,
        String recordKey,
        String episodeUrl
      }) active = (
        status: null,
        progress: 0,
        hasTotal: false,
        recordKey: '',
        episodeUrl: ''
      );
      for (final record in state.records) {
        if (record.subjectId != widget.episode.subjectID) continue;
        for (final episode in record.episodes.values) {
          if (episode.bangumiEpisodeId != widget.episode.id) continue;
          if (episode.status == DownloadStatus.completed) {
            return (
              status: DownloadStatus.completed,
              progress: 1.0,
              hasTotal: true,
              recordKey: record.key,
              episodeUrl: episode.episodeUrl,
            );
          }
          if (DownloadStatus.isActive(episode.status) ||
              (episode.status == DownloadStatus.paused &&
                  active.status == null)) {
            active = (
              status: episode.status,
              progress: episode.progressPercent.clamp(0, 100) / 100,
              hasTotal: episode.mediaType == 'direct'
                  ? episode.totalSizeBytes > 0
                  : episode.totalSegments > 0,
              recordKey: record.key,
              episodeUrl: episode.episodeUrl,
            );
          }
        }
      }
      return active;
    }));
    final status = download.status;
    final completed = status == DownloadStatus.completed;
    final downloading = status == DownloadStatus.downloading;
    final paused = status == DownloadStatus.paused;
    final tooltip = switch (status) {
      DownloadStatus.completed => l10n.downloadCompletedStatus,
      DownloadStatus.resolving => '${l10n.downloadResolving} · ${l10n.pause}',
      DownloadStatus.downloading =>
        '${l10n.downloadDownloadingStatus} · ${l10n.pause}',
      DownloadStatus.pending => '${l10n.downloadQueued} · ${l10n.pause}',
      DownloadStatus.paused => l10n.resumeDownload,
      _ => l10n.downloadResources,
    };
    return IconButton.filledTonal(
      tooltip: tooltip,
      style: downloading || paused
          ? const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.transparent),
            )
          : null,
      onPressed: _opening || _updating || completed
          ? null
          : status == null
              ? _open
              : () => _toggleDownload(download.recordKey, download.episodeUrl),
      icon: downloading || paused
          ? SizedBox.square(
              dimension: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: download.hasTotal
                          ? download.progress
                          : paused
                              ? 0
                              : null,
                      strokeWidth: 2.5,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      semanticsLabel: paused
                          ? l10n.downloadPausedStatus
                          : l10n.downloadDownloadingStatus,
                    ),
                  ),
                  Icon(
                      paused
                          ? Icons.play_arrow_rounded
                          : Icons.downloading_rounded,
                      size: 20),
                ],
              ),
            )
          : status == DownloadStatus.resolving
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Icon(completed
                  ? Icons.download_done_rounded
                  : status == DownloadStatus.pending
                      ? Icons.hourglass_top_rounded
                      : Icons.download_rounded),
    );
  }
}

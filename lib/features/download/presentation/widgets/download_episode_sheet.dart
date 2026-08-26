import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/resources_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showDownloadEpisodeSheet(BuildContext context, WidgetRef ref) {
  final container = ProviderScope.containerOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return UncontrolledProviderScope(
        container: container,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.52, 0.95],
          builder: (context, scrollController) {
            return DownloadEpisodeSheet(
              scrollController: scrollController,
            );
          },
        ),
      );
    },
  );
}

class DownloadEpisodeSheet extends ConsumerStatefulWidget {
  const DownloadEpisodeSheet({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  ConsumerState<DownloadEpisodeSheet> createState() =>
      _DownloadEpisodeSheetState();
}

class _DownloadEpisodeSheetState extends ConsumerState<DownloadEpisodeSheet> {
  final Set<String> _selectedUrls = {};
  final Set<String> _danmakuDownloadingUrls = {};
  bool _isSubmitting = false;
  late bool _downloadDanmakuEnabled;

  @override
  void initState() {
    super.initState();
    _downloadDanmakuEnabled = _storedDownloadDanmaku;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final videoSourceState = ref.watch(videoSourceProvider);
    final downloadState = ref.watch(downloadControllerProvider);
    final episodesData = ref.watch(episodesProvider).asData?.value;
    final source = _selectedSource(videoSourceState);
    final candidates = source == null
        ? <_DownloadCandidate>[]
        : _buildCandidates(
            source,
            videoSourceState,
            episodesData,
            downloadState,
          );
    final selectableCandidates = candidates.where((candidate) {
      return _canSelectCandidate(candidate.downloadEpisode);
    }).toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.downloadSelectionTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.cancel,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (source != null)
              Text(
                '${source.websiteName} - ${videoSourceState.lineName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(child: Text(l10n.noSelectableEpisodes)),
              )
            else ...[
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedUrls.length ==
                            selectableCandidates.length) {
                          _selectedUrls.clear();
                        } else {
                          _selectedUrls
                            ..clear()
                            ..addAll(
                              selectableCandidates.map((candidate) {
                                return candidate.sourceEpisode.like;
                              }),
                            );
                        }
                      });
                    },
                    icon: Icon(
                      _selectedUrls.length == selectableCandidates.length
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                    ),
                    label: Text(l10n.all),
                  ),
                  const Spacer(),
                  Text(l10n.selectedEpisodesCount(_selectedUrls.length)),
                ],
              ),
              Flexible(
                child: ListView.builder(
                  controller: widget.scrollController,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    final selected = _selectedUrls.contains(
                      candidate.sourceEpisode.like,
                    );
                    final canSelect =
                        _canSelectCandidate(candidate.downloadEpisode);
                    return CheckboxListTile(
                      value: selected && canSelect,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        candidate.displayTitle(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (candidate.downloadEpisode != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _statusText(l10n, candidate.downloadEpisode!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _statusColor(
                                  context,
                                  candidate.downloadEpisode!,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      secondary: _canDownloadDanmaku(candidate.downloadEpisode)
                          ? _danmakuDownloadingUrls.contains(
                              candidate.downloadEpisode!.episodeUrl,
                            )
                              ? const SizedBox.square(
                                  dimension: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  tooltip: l10n.downloadDanmaku,
                                  icon: const Icon(
                                    Icons.download_for_offline_rounded,
                                  ),
                                  onPressed: () => _downloadDanmaku(
                                    candidate.downloadEpisode!,
                                    sourceName: source!.websiteName,
                                  ),
                                )
                          : null,
                      onChanged: canSelect
                          ? (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selectedUrls.add(
                                    candidate.sourceEpisode.like,
                                  );
                                } else {
                                  _selectedUrls.remove(
                                    candidate.sourceEpisode.like,
                                  );
                                }
                              });
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _downloadDanmakuEnabled,
              title: Text(l10n.downloadDanmaku),
              subtitle: Text(l10n.downloadDanmakuDescription),
              onChanged: (value) {
                setState(() {
                  _downloadDanmakuEnabled = value;
                });
                Storage.setting.put(DownloadKey.downloadDanmaku, value);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedUrls.isEmpty || _isSubmitting
                    ? null
                    : () => _startDownloads(l10n, source!, candidates),
                icon: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(l10n.startDownload),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ResourcesItem? _selectedSource(VideoSourceState state) {
    if (state.videoResources.isEmpty) {
      return null;
    }
    if (state.selectedWebsiteIndex >= 0 &&
        state.selectedWebsiteIndex < state.videoResources.length) {
      return state.videoResources[state.selectedWebsiteIndex];
    }
    return state.videoResources.first;
  }

  List<_DownloadCandidate> _buildCandidates(
    ResourcesItem source,
    VideoSourceState state,
    EpisodesData? episodesData,
    DownloadState downloadState,
  ) {
    final subjectId = ref.read(playExtraProvider).playExtra.subjectId;
    final bangumiEpisodes = _episodesBySort(episodesData?.episodes);
    final lines = source.episodeResources.where((item) {
      if (state.lineName.trim().isEmpty) {
        return true;
      }
      return item.lineNames == state.lineName;
    }).toList();
    final selectedLines = lines.isEmpty ? source.episodeResources : lines;

    final candidates = <_DownloadCandidate>[];
    for (final line in selectedLines) {
      final lineIndex = source.episodeResources.indexOf(line);
      for (final sourceEpisode in line.episodes) {
        candidates.add(
          _DownloadCandidate(
            lineIndex: lineIndex,
            sourceEpisode: sourceEpisode,
            bangumiEpisode: bangumiEpisodes[sourceEpisode.episodeSort],
            downloadEpisode: _findDownloadEpisode(
              downloadState,
              subjectId: subjectId,
              sourceName: source.websiteName,
              sourceBaseUrl: source.baseUrl,
              episodeUrl: sourceEpisode.like,
            ),
          ),
        );
      }
    }
    candidates.sort((a, b) {
      final sortCompare = a.sourceEpisode.episodeSort.compareTo(
        b.sourceEpisode.episodeSort,
      );
      if (sortCompare != 0) {
        return sortCompare;
      }
      return a.lineIndex.compareTo(b.lineIndex);
    });
    return candidates;
  }

  Map<int, EpisodeData> _episodesBySort(EpisodesItem? episodes) {
    if (episodes == null) {
      return const {};
    }
    return {
      for (final episode in episodes.data) episode.sort.toInt(): episode,
    };
  }

  DownloadEpisode? _findDownloadEpisode(
    DownloadState state, {
    required int subjectId,
    required String sourceName,
    required String sourceBaseUrl,
    required String episodeUrl,
  }) {
    final normalizedUrl = _resolveEpisodeUrl(sourceBaseUrl, episodeUrl);
    for (final record in state.records) {
      if (record.subjectId == subjectId && record.sourceName == sourceName) {
        return record.episodes[normalizedUrl] ?? record.episodes[episodeUrl];
      }
    }
    return null;
  }

  String _resolveEpisodeUrl(String baseUrl, String episodeUrl) {
    final uri = Uri.tryParse(episodeUrl);
    if (uri != null && uri.hasScheme) {
      return episodeUrl;
    }
    return Uri.parse(baseUrl).resolve(episodeUrl).toString();
  }

  bool _canSelectCandidate(DownloadEpisode? episode) {
    return episode == null ||
        episode.status == DownloadStatus.paused ||
        episode.status == DownloadStatus.failed;
  }

  bool _canDownloadDanmaku(DownloadEpisode? episode) {
    return episode != null &&
        episode.status == DownloadStatus.completed &&
        !episode.danmakuDownloaded;
  }

  Future<void> _downloadDanmaku(
    DownloadEpisode episode, {
    required String sourceName,
  }) async {
    final episodeUrl = episode.episodeUrl;
    if (!_danmakuDownloadingUrls.add(episodeUrl)) {
      return;
    }
    setState(() {});
    try {
      final recordKey = DownloadRecord.buildKey(
        sourceName: sourceName,
        subjectId: ref.read(playExtraProvider).playExtra.subjectId,
      );
      await ref
          .read(downloadControllerProvider.notifier)
          .downloadDanmaku(recordKey, episodeUrl);
    } finally {
      if (mounted) {
        setState(() {
          _danmakuDownloadingUrls.remove(episodeUrl);
        });
      } else {
        _danmakuDownloadingUrls.remove(episodeUrl);
      }
    }
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
      final danmakuStatus = episode.danmakuDownloaded
          ? l10n.downloadWithDanmaku
          : l10n.downloadWithoutDanmaku;
      return '$status - $danmakuStatus';
    }
    final progress =
        '${episode.progressPercent.clamp(0, 100).toStringAsFixed(1)}%';
    final detail = episode.errorMessage.trim();
    if (detail.isNotEmpty && episode.status == DownloadStatus.failed) {
      return '$status - $detail';
    }
    return '$status - $progress';
  }

  Color _statusColor(BuildContext context, DownloadEpisode episode) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (episode.status) {
      DownloadStatus.completed => colorScheme.primary,
      DownloadStatus.failed => colorScheme.error,
      _ => colorScheme.onSurfaceVariant,
    };
  }

  Future<void> _startDownloads(
    AppLocalizations l10n,
    ResourcesItem source,
    List<_DownloadCandidate> candidates,
  ) async {
    final selected = candidates.where((candidate) {
      return _selectedUrls.contains(candidate.sourceEpisode.like) &&
          _canSelectCandidate(candidate.downloadEpisode);
    }).toList();
    if (selected.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final extra = ref.read(playExtraProvider).playExtra;
    final params = selected.map((candidate) {
      final bangumiEpisode = candidate.bangumiEpisode;
      final title = candidate.episodeTitle;
      return StartDownloadParams(
        subjectId: extra.subjectId,
        subjectName: extra.subjectName,
        subjectCover: extra.subjectCover,
        sourceName: source.websiteName,
        sourceBaseUrl: source.baseUrl,
        lineIndex: candidate.lineIndex,
        episodeUrl: candidate.sourceEpisode.like,
        episodeTitle: title,
        bangumiEpisodeId: bangumiEpisode?.id ?? 0,
        episodeSort: candidate.sourceEpisode.episodeSort.toDouble(),
        episodeIndex:
            bangumiEpisode?.sort.toInt() ?? candidate.sourceEpisode.episodeSort,
        downloadDanmaku: _downloadDanmakuEnabled,
      );
    }).toList();

    await ref.read(downloadControllerProvider.notifier).startDownloads(params);
    if (!mounted) {
      return;
    }
  }

  bool get _storedDownloadDanmaku {
    try {
      return Storage.setting.get(
        DownloadKey.downloadDanmaku,
        defaultValue: true,
      );
    } catch (_) {
      return true;
    }
  }
}

class _DownloadCandidate {
  const _DownloadCandidate({
    required this.lineIndex,
    required this.sourceEpisode,
    required this.bangumiEpisode,
    required this.downloadEpisode,
  });

  final int lineIndex;
  final Episode sourceEpisode;
  final EpisodeData? bangumiEpisode;
  final DownloadEpisode? downloadEpisode;

  String get episodeTitle {
    final title = bangumiEpisode?.nameCN.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    final fallback = bangumiEpisode?.name.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    return sourceEpisode.episodeSort.toString();
  }

  String displayTitle(AppLocalizations l10n) {
    return l10n.playEpisode(episodeTitle);
  }
}

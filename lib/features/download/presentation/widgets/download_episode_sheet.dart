import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/features/download/presentation/widgets/download_danmaku_icon.dart';
import 'package:anime_flow/features/play/presentation/providers/subject_episodes_provider.dart';
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
    // Use the full page height, outside the introduction's nested navigator.
    useRootNavigator: true,
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
  bool _isLoadingEpisodePage = false;
  int? _failedEpisodePageOffset;
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
    final subjectId = ref.watch(playExtraProvider).playExtra.subjectId;
    final subjectEpisodes =
        ref.watch(subjectEpisodesProvider(subjectId)).asData?.value;
    final source = _selectedSource(videoSourceState);
    final candidates = source == null
        ? <_DownloadCandidate>[]
        : _buildCandidates(
            source,
            videoSourceState,
            subjectEpisodes?.episodes,
            downloadState,
          );
    final selectableCandidates = candidates.where((candidate) {
      return _canSelectCandidate(candidate.downloadEpisode);
    }).toList(growable: false);
    final selectedCount = selectableCandidates
        .where(
            (candidate) => _selectedUrls.contains(candidate.sourceEpisode.like))
        .length;
    final needsEpisodePage = subjectEpisodes != null &&
        subjectEpisodes.hasMore &&
        candidates.any((candidate) => candidate.bangumiEpisode == null);
    final episodePageFailed = needsEpisodePage &&
        _failedEpisodePageOffset == subjectEpisodes.episodes.data.length;
    if (needsEpisodePage &&
        !episodePageFailed &&
        !_isLoadingEpisodePage &&
        !subjectEpisodes.isLoadingMore) {
      _isLoadingEpisodePage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadEpisodePage(subjectId);
        }
      });
    }

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
                        if (selectedCount == selectableCandidates.length) {
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
                      selectedCount == selectableCandidates.length
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                    ),
                    label: Text(l10n.all),
                  ),
                  const Spacer(),
                  Text(l10n.selectedEpisodesCount(selectedCount)),
                ],
              ),
              if (_isLoadingEpisodePage ||
                  (needsEpisodePage && subjectEpisodes.isLoadingMore))
                const LinearProgressIndicator(),
              if (episodePageFailed)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _failedEpisodePageOffset = null;
                  }),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('${l10n.episodeLoadFailed} · ${l10n.retry}'),
                ),
              Flexible(
                child: ListView.builder(
                  clipBehavior: Clip.hardEdge,
                  controller: widget.scrollController,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    final selected = _selectedUrls.contains(
                      candidate.sourceEpisode.like,
                    );
                    final canSelect =
                        _canSelectCandidate(candidate.downloadEpisode);
                    final isWatched = candidate.bangumiEpisode?.watched == true;
                    final colorScheme = Theme.of(context).colorScheme;
                    // Keep tile ink inside the scrolling viewport instead of
                    // painting it on the bottom sheet's shared Material.
                    return Material(
                      type: MaterialType.transparency,
                      child: CheckboxListTile(
                        tileColor: isWatched
                            ? colorScheme.surfaceContainerHighest
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: isWatched
                              ? BorderSide(
                                  color: colorScheme.secondaryContainer,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        value: selected && canSelect,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.episodeNumber(
                                  candidate.sourceEpisode.episodeSort,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isWatched) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.visibility_outlined,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.collectionWatched,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              candidate.episodeTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                        secondary:
                            _canDownloadDanmaku(candidate.downloadEpisode)
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
                                        icon: const DownloadDanmakuIcon(),
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
                      ),
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
                onPressed: selectedCount == 0 || _isSubmitting
                    ? null
                    : () => _startDownloads(source!, candidates),
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

  Future<void> _loadEpisodePage(int subjectId) async {
    final provider = subjectEpisodesProvider(subjectId);
    final previousCount =
        ref.read(provider).asData?.value.episodes.data.length ?? 0;
    try {
      await ref.read(provider.notifier).loadMore();
    } finally {
      if (mounted) {
        final current = ref.read(provider).asData?.value;
        setState(() {
          _isLoadingEpisodePage = false;
          // loadMore preserves the previous data on failure. Stop automatic
          // retries if the page made no progress, including empty responses.
          _failedEpisodePageOffset = current != null &&
                  current.hasMore &&
                  current.episodes.data.length <= previousCount
              ? previousCount
              : null;
        });
      }
    }
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
    EpisodesItem? episodes,
    DownloadState downloadState,
  ) {
    final subjectId = ref.read(playExtraProvider).playExtra.subjectId;
    final bangumiEpisodes = _episodesBySort(episodes);
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

  Map<num, EpisodeData> _episodesBySort(EpisodesItem? episodes) {
    if (episodes == null) {
      return const {};
    }
    // Prefer main episodes when specials share the same episode number.
    final bySort = <num, EpisodeData>{};
    for (final episode in episodes.data) {
      if (!bySort.containsKey(episode.sort) || episode.type == 0) {
        bySort[episode.sort] = episode;
      }
    }
    return bySort;
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
      LiggLogger().e('Download failed: $detail');
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
    ResourcesItem source,
    List<_DownloadCandidate> candidates,
  ) async {
    if (_isSubmitting) {
      return;
    }
    final selected = candidates.where((candidate) {
      return _selectedUrls.contains(candidate.sourceEpisode.like) &&
          _canSelectCandidate(candidate.downloadEpisode);
    }).toList();
    if (selected.isEmpty) {
      return;
    }

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

    setState(() {
      _isSubmitting = true;
      _selectedUrls.removeAll(
        selected.map((candidate) => candidate.sourceEpisode.like),
      );
    });
    try {
      await ref
          .read(downloadControllerProvider.notifier)
          .startDownloads(params);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
}

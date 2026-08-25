import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:anime_flow/shared/models/player/play/video/resources_item.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showDownloadEpisodeSheet(BuildContext context, WidgetRef ref) {
  final container = ProviderScope.containerOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return UncontrolledProviderScope(
        container: container,
        child: const DownloadEpisodeSheet(),
      );
    },
  );
}

class DownloadEpisodeSheet extends ConsumerStatefulWidget {
  const DownloadEpisodeSheet({super.key});

  @override
  ConsumerState<DownloadEpisodeSheet> createState() =>
      _DownloadEpisodeSheetState();
}

class _DownloadEpisodeSheetState extends ConsumerState<DownloadEpisodeSheet> {
  final Set<String> _selectedUrls = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final videoSourceState = ref.watch(videoSourceProvider);
    final episodesData = ref.watch(episodesProvider).asData?.value;
    final source = _selectedSource(videoSourceState);
    final candidates = source == null
        ? <_DownloadCandidate>[]
        : _buildCandidates(source, videoSourceState, episodesData);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
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
                          if (_selectedUrls.length == candidates.length) {
                            _selectedUrls.clear();
                          } else {
                            _selectedUrls
                              ..clear()
                              ..addAll(
                                candidates.map((candidate) {
                                  return candidate.sourceEpisode.like;
                                }),
                              );
                          }
                        });
                      },
                      icon: Icon(
                        _selectedUrls.length == candidates.length
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
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];
                      final selected = _selectedUrls.contains(
                        candidate.sourceEpisode.like,
                      );
                      return CheckboxListTile(
                        value: selected,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          candidate.displayTitle(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          candidate.sourceEpisode.like,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              _selectedUrls.add(candidate.sourceEpisode.like);
                            } else {
                              _selectedUrls
                                  .remove(candidate.sourceEpisode.like);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
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
  ) {
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

  Future<void> _startDownloads(
    AppLocalizations l10n,
    ResourcesItem source,
    List<_DownloadCandidate> candidates,
  ) async {
    final selected = candidates.where((candidate) {
      return _selectedUrls.contains(candidate.sourceEpisode.like);
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
      );
    }).toList();

    await ref.read(downloadControllerProvider.notifier).startDownloads(params);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    NotificationToast.show(l10n.downloadSuccess, title: l10n.tip);
  }
}

class _DownloadCandidate {
  const _DownloadCandidate({
    required this.lineIndex,
    required this.sourceEpisode,
    required this.bangumiEpisode,
  });

  final int lineIndex;
  final Episode sourceEpisode;
  final EpisodeData? bangumiEpisode;

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

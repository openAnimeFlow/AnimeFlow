import 'dart:async';
import 'dart:math' as math;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/utils/source_url.dart';
import 'package:anime_flow/core/video_source/domain/episode_source_matcher.dart';
import 'package:anime_flow/core/video_source/domain/selected_video_source.dart';
import 'package:anime_flow/core/video_source/domain/video_source.dart';
import 'package:anime_flow/core/video_source/infrastructure/webview_captcha_session.dart';
import 'package:anime_flow/features/download/application/download_resource_search.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';
import 'package:anime_flow/features/source/application/providers/source_repository_provider.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';
import 'package:anime_flow/shared/widgets/video_source/video_source_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// 搜索、预解析与确认下载都属于当前弹窗，不依赖播放页的状态。
class DownloadResourceDialog extends ConsumerStatefulWidget {
  const DownloadResourceDialog(
      {super.key,
      required this.subjectName,
      required this.subjectCover,
      required this.episode});
  final String subjectName;
  final String subjectCover;
  final EpisodeData episode;

  @override
  ConsumerState<DownloadResourceDialog> createState() =>
      _DownloadResourceDialogState();
}

class _DownloadResourceDialogState
    extends ConsumerState<DownloadResourceDialog> {
  late final DownloadResourceSearch _search;
  VideoSourceSelection? _selection;
  VideoSourceCancellation? _cancellation;
  String? _mediaUrl;
  Object? _error;
  bool _resolving = false;
  bool _submitting = false;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _search = DownloadResourceSearch(
      loadConfigs: ref.read(sourceRepositoryProvider).getSources,
    )..addListener(_onSearchChanged);
    unawaited(_runSearch(widget.subjectName));
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _runSearch(String keyword) async {
    if (keyword.trim().isEmpty || _submitting) return;
    final token = ++_searchToken;
    _cancellation?.cancel();
    setState(() {
      _selection = null;
      _mediaUrl = null;
      _error = null;
      _resolving = false;
    });
    await _search.search(keyword);
    if (mounted && token == _searchToken) _resolveFirstMatch();
  }

  void _resolveFirstMatch() {
    if (_selection != null || _submitting) return;
    final candidates = EpisodeSourceMatcher.buildCandidates(
      _search.resources,
      episodeIndex: widget.episode.sort,
    );
    if (candidates.isEmpty) return;
    final candidate = candidates.first;
    unawaited(_resolve((
      website: candidate.resource,
      line: candidate.resourceItem,
      episode: candidate.episode,
      url: resolveSourceUrl(candidate.resource.baseUrl, candidate.episode.like),
    )));
  }

  Future<void> _retry(String websiteName, {String? keyword}) async {
    final token = _searchToken;
    await _search.retry(websiteName, keyword: keyword);
    if (mounted && token == _searchToken) _resolveFirstMatch();
  }

  Future<void> _resolve(VideoSourceSelection selection) async {
    if (_submitting) return;
    _cancellation?.cancel();
    final cancellation = _cancellation = VideoSourceCancellation();
    setState(() {
      _selection = selection;
      _mediaUrl = null;
      _error = null;
      _resolving = true;
    });
    try {
      final result = await ref.read(videoSourceResolverPoolProvider).resolve(
            VideoSourceResolveRequest(
                episodeUrl: selection.url, cancellation: cancellation),
          );
      if (!mounted || cancellation.isCancelled) return;
      final uri = Uri.tryParse(result.url);
      if (uri == null ||
          !uri.hasAuthority ||
          !['http', 'https'].contains(uri.scheme)) {
        throw const VideoSourceNotFoundException();
      }
      setState(() => _mediaUrl = result.url);
    } catch (error) {
      if (mounted && !cancellation.isCancelled) setState(() => _error = error);
    } finally {
      if (mounted && !cancellation.isCancelled) {
        setState(() => _resolving = false);
      }
    }
  }

  Future<void> _startDownload() async {
    final selection = _selection;
    final mediaUrl = _mediaUrl;
    if (_submitting || selection == null || mediaUrl == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final episode = widget.episode;
      final params = StartDownloadParams(
        subjectId: episode.subjectID,
        subjectName: widget.subjectName,
        subjectCover: widget.subjectCover,
        sourceName: selection.website.websiteName,
        sourceBaseUrl: selection.website.baseUrl,
        lineIndex: selection.website.episodeResources.indexOf(selection.line),
        episodeUrl: selection.url,
        episodeTitle:
            episode.nameCN.trim().isNotEmpty ? episode.nameCN : episode.name,
        bangumiEpisodeId: episode.id,
        episodeSort: episode.sort.toDouble(),
        episodeIndex: selection.episode.episodeSort,
        networkMediaUrl: mediaUrl,
      );
      final repository = ref.read(downloadRepositoryProvider);
      final existing =
          repository.getRecord(params.recordKey)?.episodes[selection.url];
      if (existing != null &&
          [
            DownloadStatus.pending,
            DownloadStatus.resolving,
            DownloadStatus.downloading,
            DownloadStatus.completed
          ].contains(existing.status)) {
        if (mounted) Navigator.of(context).pop(false);
        return;
      }
      await ref.read(downloadControllerProvider.notifier).startDownload(params);
      final result =
          repository.getRecord(params.recordKey)?.episodes[selection.url];
      if (result == null || result.status == DownloadStatus.failed) {
        throw StateError(result?.errorMessage ?? l10n.downloadFailedStatus);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _cancellation?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selection = _selection;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 1000,
        height: math.min(760, MediaQuery.sizeOf(context).height * .85),
        child: Column(children: [
          Expanded(
              child: AbsorbPointer(
            absorbing: _submitting,
            child: VideoSourceDialog(
              subjectName: widget.subjectName,
              resources: _search.resources,
              searchKeyword: _search.keyword,
              episodeNumber: widget.episode.sort,
              closeOnSelection: false,
              keyboardInsetHandled: true,
              selectedSource: selection == null
                  ? null
                  : SelectedVideoSource(
                      websiteName: selection.website.websiteName,
                      websiteIcon: selection.website.websiteIcon,
                      resourceTitle: selection.line.subjectsTitle,
                      lineName: selection.line.lineNames,
                      videoUrl: selection.url,
                    ),
              onSearch: (keyword) => unawaited(_runSearch(keyword)),
              onRetry: (name, {keyword}) =>
                  unawaited(_retry(name, keyword: keyword)),
              createCaptchaSession: WebviewCaptchaSession.new,
              onCaptchaVerified: (name) {
                final token = _searchToken;
                unawaited(
                    Future<void>.delayed(const Duration(seconds: 3), () async {
                  if (mounted && token == _searchToken) await _retry(name);
                }));
              },
              onSourceSelected: (value) => unawaited(_resolve(value)),
            ),
          )),
          if (_search.loading) const LinearProgressIndicator(),
          if (_search.error != null ||
              (!_search.loading && _search.resources.isEmpty))
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text(_search.error == null
                      ? l10n.noPlayableSourceHint
                      : l10n.error),
                  TextButton(
                      onPressed: () => _runSearch(_search.keyword),
                      child: Text(l10n.retry)),
                ])),
          if (selection != null) ...[
            const Divider(height: 1),
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        '${selection.website.websiteName} · ${selection.line.lineNames} · '
                        '${l10n.episodeNumber(selection.episode.episodeSort)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    if (_resolving) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(l10n.downloadResolving),
                    ],
                    if (_mediaUrl != null)
                      Text(_mediaUrl!,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (_error != null)
                      Text('${l10n.error}: $_error',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (_error != null && !_resolving)
                        TextButton(
                            onPressed:
                                _submitting ? null : () => _resolve(selection),
                            child: Text(l10n.retry)),
                      FilledButton.icon(
                        onPressed: _mediaUrl == null || _submitting
                            ? null
                            : _startDownload,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.download_rounded),
                        label: Text(l10n.startDownload),
                      ),
                    ]),
                  ],
                )),
          ],
        ]),
      ),
    );
  }
}

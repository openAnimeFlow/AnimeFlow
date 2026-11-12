import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/recommendations.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/danmaku_card.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/episodes.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/resources.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/core/network/core/flow_response.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/args/video_resource_download_route_args.dart';
import 'package:anime_flow/shared/widgets/collection_button.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_state_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_query_providers.dart';
import 'package:anime_flow/features/play/presentation/widgets/dialog/play_video_source_dialog.dart';
import 'package:anime_flow/features/play/presentation/widgets/layout_toggle_icon.dart';
import 'package:anime_flow/features/play/presentation/widgets/player_settings_sheet.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/play_details_sheet.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anime_flow/features/subject_episodes/application/subject_episodes_provider.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';

@Dependencies([
  playExtra,
  AnimeInfo,
  Episodes,
  playSession,
  PlayStateNotifier,
  VideoUiNotifier,
  VideoSourceNotifier,
  DanmakuStateNotifier,
  recommendation,
  animeInfoArgs,
  SubjectComments,
  SubjectStills,
  SubjectCharacters,
  SubjectProducers,
  SubjectRelated,
])
class IntroduceView extends StatefulWidget {
  const IntroduceView({super.key});

  @override
  State<IntroduceView> createState() => _IntroduceViewState();
}

class _IntroduceViewState extends State<IntroduceView>
    with AutomaticKeepAliveClientMixin {
  final _collectionMenuTurns = ValueNotifier<double>(0);
  bool _isGridView = false;
  bool _detailsOpen = false;

  Future<void> _showDetails() async {
    if (_detailsOpen) return;
    _detailsOpen = true;
    try {
      await showPlayerSettingsSheet(
        context: context,
        label: AppLocalizations.of(context).detailsTitle,
        child: PlayerSettingsSheet(
          closeOnMinExtent: true,
          builder: (context, scrollController, isBottomSheet) =>
              PlayDetailsSheet(scrollController: scrollController),
        ),
      );
    } finally {
      _detailsOpen = false;
    }
  }

  void _loadMoreEpisodes(WidgetRef ref, {bool retry = false}) {
    final extra = ref.read(playExtraProvider);
    if (extra.isOfflineMode) return;
    final provider = subjectEpisodesProvider(extra.playExtra.subjectId);
    final state = ref.read(provider).asData?.value;
    if (state == null ||
        !state.hasMore ||
        state.isLoadingMore ||
        (!retry && state.loadMoreError != null)) {
      return;
    }
    ref.read(provider.notifier).loadMore();
  }

  void _retryEpisodes(WidgetRef ref) {
    final extra = ref.read(playExtraProvider);
    if (extra.isOfflineMode) return;
    ref
        .read(subjectEpisodesProvider(extra.playExtra.subjectId).notifier)
        .retry();
  }

  Future<void> _updateEpisodeWatched(WidgetRef ref, EpisodeData episode) async {
    if (ref.read(playExtraProvider).isOfflineMode) return;
    try {
      await ref.read(playSessionProvider).updateEpisodeWatched(
            episode.id,
            watched: episode.watched != true,
          );
    } on AnimeFlowApiException catch (e) {
      if (!mounted) return;
      NotificationToast.show(e.message, title: '更新失败');
    } catch (e) {
      if (!mounted) return;
      NotificationToast.show(e.toString(), title: '更新失败');
    }
  }

  void _showSourceDrawer(String subjectName) {
    showPlayerSettingsSheet(
      context: context,
      label: AppLocalizations.of(context).videoSource,
      child: PlayerSettingsSheet(
        avoidKeyboard: true,
        initialSize: 0.60,
        snapSizes: const [0.3, 0.52, 0.95],
        closeOnMinExtent: true,
        builder: (context, scrollController, isBottomSheet) =>
            PlayVideoSourceDialog(
          keyboardInsetHandled: isBottomSheet,
          scrollController: scrollController,
          subjectName: subjectName,
        ),
      ),
    );
  }

  Future<void> _openSourcePage(String videoUrl) async {
    await launchUrl(Uri.parse(videoUrl.trim()),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _copySourcePage(String videoUrl) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: videoUrl.trim()));
    NotificationToast.show(l10n.sourceLinkCopied, title: l10n.copied);
  }

  @override
  void dispose() {
    _collectionMenuTurns.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Consumer(builder: (context, ref, child) {
              final extra = ref.watch(playExtraProvider).playExtra;
              final isLoggedIn = ref.watch(isLoggedInProvider).value ?? false;
              final subject = ref.watch(animeInfoProvider).asData?.value;
              final l10n = AppLocalizations.of(context);

              return Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _showDetails,
                      borderRadius: BorderRadius.circular(10),
                      child: Text(
                        extra.subjectName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isLoggedIn && subject != null)
                    CollectionButton(
                      key: ValueKey(extra.subjectId),
                      collectType:
                          collectTypeFromApiType(subject.interest?.type),
                      onMenuOpen: () => _collectionMenuTurns.value = 0.5,
                      onMenuClose: () => _collectionMenuTurns.value = 0,
                      buttonBuilder: (context, label, icon, onPressed) {
                        return IconButton(
                          tooltip: label,
                          onPressed: onPressed,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          icon: ValueListenableBuilder<double>(
                            valueListenable: _collectionMenuTurns,
                            builder: (context, turns, child) =>
                                AnimatedRotation(
                              turns: turns,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: child,
                            ),
                            child: const Icon(Icons.expand_more_outlined),
                          ),
                        );
                      },
                      onCollectTypeChanged: (newType) async {
                        try {
                          await ref
                              .read(animeInfoProvider.notifier)
                              .updateCollectionType(newType.value);
                        } on AnimeFlowApiException catch (e) {
                          NotificationToast.show(
                            e.message,
                            title: l10n.updateFailed,
                          );
                          rethrow;
                        } catch (e) {
                          NotificationToast.show(
                            e.toString(),
                            title: l10n.updateFailed,
                          );
                          rethrow;
                        }
                      },
                    ),
                ],
              );
            }),
            const SizedBox(height: 5),
            //章节
            Consumer(builder: (context, ref, child) {
              final l10n = AppLocalizations.of(context);
              final episodesAsync = ref.watch(episodesProvider);
              final episodes = episodesAsync.value?.episodes?.data;
              final extra = ref.watch(playExtraProvider);
              final isPlaying = ref.watch(
                playStateProvider.select((state) => state.playing),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.episodeSelection),
                      if (episodes != null && episodes.isNotEmpty)
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  appNavigatorOf(context)
                                      .openVideoResourceDownload<void>(
                                    VideoResourceDownloadRouteArgs(
                                      subjectName: extra.playExtra.subjectName,
                                      subjectCover:
                                          extra.playExtra.subjectCover,
                                      episodes: episodes,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.download_rounded)),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _isGridView = !_isGridView),
                              icon: LayoutToggleIcon(isGridView: _isGridView),
                              tooltip: _isGridView
                                  ? l10n.switchToList
                                  : l10n.switchToGrid,
                            ),
                          ],
                        ),
                    ],
                  ),
                  EpisodesListView(
                    episodesAsync: episodesAsync,
                    isGridView: _isGridView,
                    subjectCover: extra.playExtra.subjectCover,
                    isPlaying: isPlaying,
                    onEpisodeSelected: (episode) => ref
                        .read(episodesProvider.notifier)
                        .selectEpisode(episode.id),
                    onToggleWatched: extra.isOfflineMode
                        ? null
                        : (episode) => _updateEpisodeWatched(ref, episode),
                    onLoadMore: () => _loadMoreEpisodes(ref),
                    onRetry: () => _retryEpisodes(ref),
                    onRetryLoadMore: () => _loadMoreEpisodes(ref, retry: true),
                  ),
                ],
              );
            }),
            //数据源
            Consumer(builder: (context, ref, child) {
              final state = ref.watch(videoSourceProvider);
              final hasSourceUrl = state.videoUrl.trim().isNotEmpty;
              return VideoResourcesView(
                isSearchCompleted: state.isSearchCompleted,
                webSiteTitle: state.webSiteTitle,
                webSiteIcon: state.webSiteIcon,
                resourceTitle: state.resourceTitle,
                lineName: state.lineName,
                onSwitchSource: () => _showSourceDrawer(
                    ref.read(playExtraProvider).playExtra.subjectName),
                onOpenSourcePage:
                    hasSourceUrl ? () => _openSourcePage(state.videoUrl) : null,
                onCopySourcePage:
                    hasSourceUrl ? () => _copySourcePage(state.videoUrl) : null,
              );
            }),
            //弹幕
            const DanmakuCard(),
            const RecommendationsView(),
          ],
        ),
      ),
    );
  }
}

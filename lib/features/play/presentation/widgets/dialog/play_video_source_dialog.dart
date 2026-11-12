import 'dart:async';

import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/play/presentation/providers/play_session_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/shared/widgets/video_source/video_source_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([Episodes, VideoSourceNotifier, playSession, VideoUiNotifier])
class PlayVideoSourceDialog extends ConsumerWidget {
  const PlayVideoSourceDialog({
    super.key,
    required this.subjectName,
    this.keyboardInsetHandled = false,
    this.scrollController,
  });

  final String subjectName;
  final bool keyboardInsetHandled;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodeIndex = ref.watch(episodesProvider.select(
      (state) => state.asData?.value.episodeIndex ?? 0,
    ));
    final source = ref.watch(videoSourceProvider.select((state) => (
          resources: state.videoResources,
          keyword: state.keyword,
          selectedWebsiteIndex: state.selectedWebsiteIndex,
          selectedSource: state.selectedSource,
        )));
    final controller = ref.read(videoSourceProvider.notifier);
    final playSession = ref.read(playSessionProvider);
    final videoUi = ref.read(videoUiProvider.notifier);

    return VideoSourceDialog(
      subjectName: subjectName,
      resources: source.resources,
      searchKeyword: source.keyword,
      initialSearchDraft: ref.read(videoSourceProvider).manualSearchDraft,
      selectedWebsiteIndex: source.selectedWebsiteIndex,
      selectedSource: source.selectedSource,
      episodeNumber: episodeIndex,
      keyboardInsetHandled: keyboardInsetHandled,
      scrollController: scrollController,
      onSearchDraftChanged: controller.setManualSearchDraft,
      onWebsiteSelected: controller.setSelectedWebsiteIndex,
      onSearch: (keyword) => controller.initResources(
        keyword,
        preserveCurrentPlayback:
            ref.read(videoSourceProvider).videoUrl.isNotEmpty,
      ),
      onRetry: (websiteName, {keyword}) {
        if (controller.active) {
          unawaited(controller.retryResources(websiteName, keyword: keyword));
        }
      },
      createCaptchaSession: () => ref.read(captchaSessionFactoryProvider)(),
      onCaptchaVerified: (websiteName) {
        controller.markCaptchaVerified(websiteName);
        unawaited(Future<void>.delayed(const Duration(seconds: 3), () async {
          if (controller.active) await controller.retryResources(websiteName);
        }));
      },
      onSourceSelected: (selection) {
        controller.bindManualSourceForCurrentEpisode(
          websiteName: selection.website.websiteName,
          websiteIcon: selection.website.websiteIcon,
          resourceTitle: selection.line.subjectsTitle,
          lineName: selection.line.lineNames,
          videoUrl: selection.url,
        );
        unawaited(playSession.stop());
        unawaited(controller.loadVideoPage(selection.url));
        videoUi.showParsingIndicator();
      },
    );
  }
}

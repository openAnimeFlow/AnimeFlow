import 'dart:async';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/logger/app_log.dart';
import 'package:anime_flow/core/video_source/domain/selected_video_source.dart';
import 'package:anime_flow/features/play/domain/play_source_selection.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/shared/widgets/video_source/video_source_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([Episodes, VideoSourceNotifier])
class PlayVideoSourceDialog extends ConsumerStatefulWidget {
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
  ConsumerState<PlayVideoSourceDialog> createState() =>
      _PlayVideoSourceDialogState();
}

class _PlayVideoSourceDialogState extends ConsumerState<PlayVideoSourceDialog> {
  bool _pickingLocalVideo = false;

  Future<void> _pickLocalVideo() async {
    if (_pickingLocalVideo) return;
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(videoSourceProvider.notifier);
    setState(() => _pickingLocalVideo = true);
    try {
      final file = await controller.pickLocalVideo(
        dialogTitle: l10n.chooseLocalVideo,
        isPickerActive: () => mounted,
      );
      if (file == null || !mounted) return;
      unawaited(controller.openSelectedSource(file));
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      logError('选择本地视频失败', error: error, stackTrace: stackTrace);
      if (mounted) NotificationToast.show(l10n.openFailed);
    } finally {
      if (mounted) setState(() => _pickingLocalVideo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

    return VideoSourceDialog(
      subjectName: widget.subjectName,
      resources: source.resources,
      searchKeyword: source.keyword,
      initialSearchDraft: ref.read(videoSourceProvider).manualSearchDraft,
      selectedWebsiteIndex: source.selectedWebsiteIndex,
      selectedSource: source.selectedSource,
      episodeNumber: episodeIndex,
      keyboardInsetHandled: widget.keyboardInsetHandled,
      scrollController: widget.scrollController,
      closeOnSelection: false,
      sourceAction: OutlinedButton.icon(
        onPressed:
            _pickingLocalVideo || episodeIndex <= 0 ? null : _pickLocalVideo,
        icon: _pickingLocalVideo
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.folder_open_rounded, size: 20),
        label: Text(_pickingLocalVideo
            ? l10n.preparingLocalVideo
            : l10n.chooseLocalVideo),
      ),
      onSearchDraftChanged: controller.setManualSearchDraft,
      onWebsiteSelected: controller.setSelectedWebsiteIndex,
      onSearch: (keyword) => controller.initResources(
        keyword,
        preserveCurrentPlayback:
            ref.read(videoSourceProvider).hasSelectedSource,
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
        final source = OnlineEpisodeSource(SelectedVideoSource(
          websiteName: selection.website.websiteName,
          websiteIcon: selection.website.websiteIcon,
          resourceTitle: selection.line.subjectsTitle,
          lineName: selection.line.lineNames,
          videoUrl: selection.url,
        ));
        unawaited(controller.openSelectedSource(source));
        Navigator.of(context).pop();
      },
    );
  }
}

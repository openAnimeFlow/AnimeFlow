import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:anime_flow/features/play/presentation/widgets/source_drawers/video_source_drawers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum _SourceAction { openPageUrl, copyPageUrl }

class VideoResourcesView extends ConsumerStatefulWidget {
  const VideoResourcesView({super.key});

  @override
  ConsumerState<VideoResourcesView> createState() => _VideoResourcesViewState();
}

class _VideoResourcesViewState extends ConsumerState<VideoResourcesView> {
  bool _isSourceActionMenuOpen = false;

  void _showSourceDrawer() {
    final playController = ref.read(playSessionProvider);
    final videoUiStateController = ref.read(videoUiProvider.notifier);
    final videoSourceController = ref.read(videoSourceProvider.notifier);
    void onVideoUrlSelected(String url) {
      playController.player.stop();
      videoSourceController.loadVideoPage(url);
      videoUiStateController
          .updateIndicatorType(VideoControlsIndicatorType.parsingIndicator);
      videoUiStateController
          .updateMainAxisAlignmentType(MainAxisAlignment.center);
      videoUiStateController.showIndicator();
    }

    final subjectName = ref.read(playExtraProvider).playExtra.subjectName;
    final providerContainer = ProviderScope.containerOf(context);

    if (ref.read(playStateProvider).isWideScreen) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "SourceDrawer",
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
        pageBuilder: (context, animation, secondaryAnimation) {
          return UncontrolledProviderScope(
            container: providerContainer,
            child: VideoSourceDrawers(
              isBottomSheet: false,
              onVideoUrlSelected: onVideoUrlSelected,
              videoSourceController: videoSourceController,
              subjectName: subjectName,
            ),
          );
        },
      );
    } else {
      final drawerController = DraggableScrollableController();
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return UncontrolledProviderScope(
            container: providerContainer,
            child: DraggableScrollableSheet(
              controller: drawerController,
              expand: false,
              initialChildSize: 0.60,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              snap: true,
              snapSizes: const [0.52, 0.95],
              builder: (context, scrollController) {
                return VideoSourceDrawers(
                  isBottomSheet: true,
                  scrollController: scrollController,
                  draggableController: drawerController,
                  onVideoUrlSelected: onVideoUrlSelected,
                  videoSourceController: videoSourceController,
                  subjectName: subjectName,
                );
              },
            ),
          );
        },
      );
    }
  }

  Future<void> _openSourcePageInBrowser(String videoUrl) async {
    final url = videoUrl.trim();
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _copySourcePageUrl(String videoUrl) async {
    final l10n = AppLocalizations.of(context);
    final url = videoUrl.trim();
    await Clipboard.setData(ClipboardData(text: url));
    NotificationToast.show(l10n.sourceLinkCopied, title: l10n.copied);
  }

  Widget _buildSourceActionMenu(String videoUrl, AppLocalizations l10n) {
    return DropDownMenu<_SourceAction>(
      items: _SourceAction.values,
      tooltip: l10n.sourceActions,
      disableSelected: false,
      onOpenedChanged: (isOpen) {
        if (!mounted || _isSourceActionMenuOpen == isOpen) {
          return;
        }
        setState(() {
          _isSourceActionMenuOpen = isOpen;
        });
      },
      buttonBuilder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        return SizedBox.square(
          dimension: 50,
          child: AnimatedRotation(
            turns: _isSourceActionMenuOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorScheme.primary,
              size: 30,
            ),
          ),
        );
      },
      itemBuilder: (context, action, _) {
        final (icon, label) = switch (action) {
          _SourceAction.openPageUrl => (
              Icons.open_in_browser_rounded,
              l10n.openPlaybackPage
            ),
          _SourceAction.copyPageUrl => (
              Icons.content_copy_rounded,
              l10n.copySourceLink
            ),
        };
        return SizedBox(
          width: 150,
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
            ],
          ),
        );
      },
      onSelected: (action) {
        switch (action) {
          case _SourceAction.openPageUrl:
            _openSourcePageInBrowser(videoUrl);
          case _SourceAction.copyPageUrl:
            _copySourcePageUrl(videoUrl);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final videoSourceState = ref.watch(videoSourceProvider);
    final hasSourceUrl = videoSourceState.videoUrl.trim().isNotEmpty;
    final resourceTitle = videoSourceState.resourceTitle.trim();
    final lineName = videoSourceState.lineName.trim();
    final displayLineName = lineName.isEmpty ? '' : lineName;
    final resourceDetail = [
      if (resourceTitle.isNotEmpty) resourceTitle,
      if (displayLineName.isNotEmpty) l10n.lineLabel(displayLineName),
    ].join(' - ');
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.videoSource,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (videoSourceState.isSearchCompleted ||
                      videoSourceState.webSiteTitle.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: AnimationNetworkImage(
                                height: 25,
                                width: 25,
                                url: videoSourceState.webSiteIcon,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                videoSourceState.webSiteTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (resourceDetail.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            resourceDetail,
                            softWrap: true,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Row(
                      children: [
                        Text(l10n.autoSelectingResource),
                        const SizedBox(width: 5),
                        const SizedBox(
                          height: 10,
                          width: 10,
                          child: CircularProgressIndicator(),
                        )
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _showSourceDrawer,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  icon: const Icon(Icons.sync_alt_rounded),
                  label: Text(l10n.switchSource),
                ),
                if (hasSourceUrl) ...[
                  _buildSourceActionMenu(videoSourceState.videoUrl, l10n),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

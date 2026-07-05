import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/video_ui_provider.dart';
import 'package:anime_flow/pages/play/providers/video_source_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:anime_flow/widget/play_content/source_drawers/video_source_drawers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoResourcesView extends ConsumerStatefulWidget {
  const VideoResourcesView({super.key});

  @override
  ConsumerState<VideoResourcesView> createState() => _VideoResourcesViewState();
}

class _VideoResourcesViewState extends ConsumerState<VideoResourcesView> {
  void _showSourceDrawer() {
    final playController = ref.read(playSessionProvider);
    final videoUiStateController =
        ref.read(videoUiStateControllerProvider.notifier);
    final videoSourceController =
        ref.read(videoSourceControllerProvider.notifier);
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

  @override
  Widget build(BuildContext context) {
    final videoSourceState = ref.watch(videoSourceControllerProvider);
    return Stack(
      children: [
        Card(
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
                      const Text(
                        '数据源',
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (videoSourceState.isSearchCompleted ||
                          videoSourceState.webSiteTitle.isNotEmpty)
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
                            Text(
                              videoSourceState.webSiteTitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        )
                      else
                        const Row(
                          children: [
                            Text('自动选择资源中'),
                            SizedBox(width: 5),
                            SizedBox(
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
                OutlinedButton.icon(
                  onPressed: _showSourceDrawer,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  icon: const Icon(Icons.sync_alt_rounded),
                  label: const Text("切换源"),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

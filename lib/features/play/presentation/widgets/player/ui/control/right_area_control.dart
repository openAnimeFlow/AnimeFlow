import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/utils/player_screenshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RightAreaControl extends ConsumerWidget {
  const RightAreaControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShowControlsUi =
        ref.watch(videoUiProvider.select((state) => state.isShowControlsUi));
    final fullscreen =
        ref.watch(playStateProvider.select((s) => s.isFullscreen));
    final position = ref.watch(playStateProvider.select((s) => s.position));
    final isWideScreen =
        ref.watch(playStateProvider.select((s) => s.isWideScreen));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: isShowControlsUi
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                key: ValueKey<bool>(isShowControlsUi),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  position > Duration.zero && (isWideScreen || fullscreen)
                      ? InkWell(
                          onTap: () => capturePlayerScreenshot(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 1,
                                  color: Colors.white10,
                                )),
                            child: const Icon(Icons.camera_alt_outlined,
                                color: Colors.white70, size: 30),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            )
          : SizedBox.shrink(
              key: ValueKey<bool>(isShowControlsUi),
            ),
    );
  }
}

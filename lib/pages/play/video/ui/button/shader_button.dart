import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/video_ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShaderButton extends ConsumerWidget {
  final PlaySession playController;

  const ShaderButton({super.key, required this.playController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoUiStateController =
        ref.read(videoUiStateControllerProvider.notifier);
    final currentType = ref.watch(
      playStateProvider.select((state) => state.superResolutionType),
    );
    final labels = ['关闭', '效率档', '质量档'];

    return MenuAnchor(
      onOpen: () {
        videoUiStateController.cancelUiTimer();
      },
      onClose: () {
        videoUiStateController.hideControlsUi(
            duration: const Duration(seconds: 2));
      },
      menuChildren: List<MenuItemButton>.generate(
        labels.length,
        (int index) {
          final type = index + 1;
          final isSelected = currentType == type;

          return MenuItemButton(
            onPressed: () {
              playController.setShader(type);
            },
            child: Container(
              height: 48,
              constraints: const BoxConstraints(minWidth: 112),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        final themePrimary = Theme.of(context).colorScheme.primary;
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: currentType == 2 || currentType == 3
                  ? themePrimary.withValues(alpha: 0.5)
                  : null,
            ),
            child: Text(
              '4k',
              style: TextStyle(
                  color: themePrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
        );
      },
    );
  }
}

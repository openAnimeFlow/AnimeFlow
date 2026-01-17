import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShaderButton extends StatelessWidget {
  const ShaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    final playController = Get.find<PlayController>();
    final videoUiStateController = Get.find<VideoUiStateController>();
    final videoStateController = Get.find<VideoStateController>();

    return Obx(() {
      final currentType = playController.superResolutionType.value;
      final player = videoStateController.player;

      return MenuAnchor(
        onOpen: () {
          videoUiStateController.cancelUiTimer();
        },
        onClose: () {
          videoUiStateController.hideControlsUi(
              duration: const Duration(seconds: 2));
        },
        menuChildren: List<MenuItemButton>.generate(
          3,
          (int index) {
            final type = index + 1;
            final labels = ['关闭', '效率档', '质量档'];
            final isSelected = currentType == type;

            return MenuItemButton(
              onPressed: () {
                Get.log('超分辨率型: $type');
                playController.setShader(type, player: player);
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
                    fontSize: 20),
              ),
            ),
          );
        },
      );
    });
  }
}

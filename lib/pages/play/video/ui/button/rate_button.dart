import 'package:anime_flow/controllers/play/play_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RateButton extends StatelessWidget {
  final PlayController playController;
  final VideoUiStateController videoUiStateController;

  const RateButton(
      {super.key,
      required this.playController,
      required this.videoUiStateController});

  static const List<double> _speeds = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    2.0,
    3.0,
    4.0,
  ];

  @override
  Widget build(BuildContext context) {

    return Obx(() {
      final currentRate = playController.rate.value;
      final colorScheme = Theme.of(context).colorScheme;

      return MenuAnchor(
        onOpen: () {
          videoUiStateController.cancelUiTimer();
        },
        onClose: () {
          videoUiStateController.hideControlsUi(
            duration: const Duration(seconds: 2),
          );
        },
        menuChildren: _speeds.map((speed) {
          final isSelected = currentRate == speed;
          return MenuItemButton(
            onPressed: () {
              playController.startSpeedBoost(speed);
            },
            child: SizedBox(
              width: 112,
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${speed}x',
                      style: TextStyle(
                        color: isSelected ? colorScheme.primary : null,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
        builder:
            (BuildContext context, MenuController controller, Widget? child) {
          return TextButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: Text(currentRate == 1.0 ? '倍速' : '${currentRate}x'),
          );
        },
      );
    });
  }
}

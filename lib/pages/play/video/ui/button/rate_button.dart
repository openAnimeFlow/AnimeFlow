import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RateButton extends StatelessWidget {
  const RateButton({super.key});

  @override
  Widget build(BuildContext context) {
    final videoStateController = Get.find<VideoStateController>();

    /// 构建倍速选项列表
    List<Widget> buildSpeedOptions(BuildContext context) {
      final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0];
      return speeds.map((speed) {
        return Obx(() {
          final isSelected = videoStateController.rate.value == speed;
          return ListTile(
            title: Text(
              '${speed}x',
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              videoStateController.startSpeedBoost(speed);
              Navigator.of(context).pop();
            },
          );
        });
      }).toList();
    }

    void showSpeedDrawer(BuildContext context) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '倍速选择',
        barrierColor: Colors.black.withValues(alpha: 0.5),
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const SizedBox.shrink();
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ));

          return SlideTransition(
            position: slideAnimation,
            child: Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 280,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).drawerTheme.backgroundColor ??
                        Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 标题栏
                      Container(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top,
                            left: 16,
                            right: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '选择播放倍速',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: '关闭',
                            ),
                          ],
                        ),
                      ),
                      // 倍速选项列表
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: buildSpeedOptions(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return TextButton(
        onPressed: () {
          showSpeedDrawer(context);
        },
        child: Obx(
          () => Text(videoStateController.rate.value == 1.0
              ? '倍速'
              : '${videoStateController.rate.value}x'),
        ));
  }
}

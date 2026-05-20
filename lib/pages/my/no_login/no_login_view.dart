import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/controllers/my_controller.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum _NoLoginOverflowAction { settings, playRecord }

class NoLoginView extends StatelessWidget {
  const NoLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final myController = Get.find<MyController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyLarge;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top, left: 16, right: 16),
          child: Row(
            children: [
              const Spacer(),
              PopupMenuButton<_NoLoginOverflowAction>(
                tooltip: '更多',
                position: PopupMenuPosition.under,
                offset: const Offset(0, 4),
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 28,
                  color: colorScheme.onSurface,
                ),
                onSelected: (action) {
                  switch (action) {
                    case _NoLoginOverflowAction.settings:
                      const SettingsRoute().push(context);
                    case _NoLoginOverflowAction.playRecord:
                      const PlayRecordRoute().push(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<_NoLoginOverflowAction>(
                    value: _NoLoginOverflowAction.settings,
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text('设置', style: textStyle),
                      ],
                    ),
                  ),
                  PopupMenuItem<_NoLoginOverflowAction>(
                    value: _NoLoginOverflowAction.playRecord,
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.smart_display_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text('播放记录', style: textStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.transparent,
                  child: Image.asset(AssetsPathConstants.logo)),
              const Text(
                '未登录',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Obx(
                () {
                  final isAuthorizing = myController.isOAuthAuthorizing.value;
                  return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isAuthorizing
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 左侧
                          ElevatedButton(
                            onPressed: null, // 等待中禁用
                            style: ElevatedButton.styleFrom(
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                  topRight: Radius.circular(5),
                                  bottomRight: Radius.circular(5),
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 3),
                                ),
                                SizedBox(width: 8),
                                Text('正在等待登录结果'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          // 右侧
                          SizedBox(
                            width: 76,
                            child: OutlinedButton(
                              onPressed: () {
                                if (isAuthorizing) {
                                  myController.cancelOAuthWaiting();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                    topLeft: Radius.circular(5),
                                    bottomLeft: Radius.circular(5),
                                  ),
                                ),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(
                                      alpha: 0.12,
                                    ),
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                                side:
                                    const BorderSide(color: Colors.transparent),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                              child: const Text('取消',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                      )
                      : ElevatedButton(
                        onPressed: () => myController.openOAuthPage(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('登录授权'),
                      ),
                );
                },
              ),
            ],
          ),
        )
      ],
    );
  }
}

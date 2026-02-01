import 'package:anime_flow/controllers/main_page/main_page_state.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../my_controller.dart';

class NoLoginView extends StatefulWidget {
  const NoLoginView({super.key});

  @override
  State<NoLoginView> createState() => _NoNoLoginView();
}

class _NoNoLoginView extends State<NoLoginView> {
  bool _isAuthorizing = false;
  late MainPageState mainPageState;

  @override
  void initState() {
    super.initState();
    mainPageState = Get.find<MainPageState>();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Row(
            children: [
              const Spacer(),
              MenuAnchor(
                alignmentOffset: const Offset(-80, 0),
                crossAxisUnconstrained: false,
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => Get.toNamed(RouteName.settings),
                    child: const Row(
                      children: [Icon(Icons.settings_outlined), Text('设置')],
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () => Get.toNamed(RouteName.playRecord),
                    child: const Row(
                      children: [Icon(Icons.smart_display_outlined), Text('播放记录')],
                    ),
                  )
                ],
                builder: (BuildContext context, MenuController controller,
                    Widget? child) {
                  return InkWell(
                    onTap: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: const Icon(
                      Icons.notes_outlined,
                      size: 30,
                    ),
                  );
                },
              )
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.transparent,
                  child: AnimationNetworkImage(
                      url:
                          'https://gitee.com/anime-flow/anime-flow-assets/raw/master/logo.png')),
              const Text(
                '未登录',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isAuthorizing
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
                                if (_isAuthorizing) {
                                  setState(() {
                                    _isAuthorizing = false;
                                  });
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
                        onPressed: () {
                          MyController.openOAuthPage();
                          setState(() {
                            _isAuthorizing = true;
                          });
                        },
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
              ),
            ],
          ),
        )
      ],
    );
  }
}

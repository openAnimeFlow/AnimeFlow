import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';

import 'my_controller.dart';

class NoLoginView extends StatefulWidget {
  const NoLoginView({super.key});

  @override
  State<NoLoginView> createState() => _NoNoLoginView();
}

class _NoNoLoginView extends State<NoLoginView> {
  bool _isAuthorizing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Spacer(),
          IconButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteName.settings),
              icon: Icon(Icons.settings))
        ]),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 100,
                backgroundColor: Colors.transparent,
                child: AnimationNetworkImage(url: 'https://gitee.com/anime-flow/anime-flow-assets/raw/master/logo.png')
              ),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
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

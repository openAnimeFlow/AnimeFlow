import 'package:flutter/material.dart';

import 'my_controller.dart';

class NoLoginView extends StatelessWidget {
  const NoLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 用户头像
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.person, size: 60, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // 用户名
          const Text(
            '未登录',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // 登录按钮
          //TODO 添加状态管理
          ElevatedButton(
            onPressed: () {
              MyController.openOAuthPage();
            },
            child: const Text('登录授权'),
          ),
        ],
      ),
    );;
  }
}

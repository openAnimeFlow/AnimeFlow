import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:anime_flow/providers/user/user_controller.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/drop_down_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _NoLoginOverflowAction { settings, playRecord }

class NoLoginView extends StatelessWidget {
  const NoLoginView({super.key});

  @override
  Widget build(BuildContext context) {
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
              DropDownMenu<_NoLoginOverflowAction>(
                tooltip: '更多菜单',
                items: _NoLoginOverflowAction.values,
                disableSelected: false,
                buttonBuilder: (context, _) => Icon(
                  Icons.notes_outlined,
                  size: 28,
                  color: colorScheme.onSurface,
                ),
                itemBuilder: (context, action, _) {
                  final (icon, label) = switch (action) {
                    _NoLoginOverflowAction.settings =>
                      (Icons.settings_outlined, '设置'),
                    _NoLoginOverflowAction.playRecord =>
                      (Icons.smart_display_outlined, '播放记录'),
                  };
                  return SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(label, style: textStyle),
                      ],
                    ),
                  );
                },
                onSelected: (action) {
                  switch (action) {
                    case _NoLoginOverflowAction.settings:
                      const SettingsRoute().push(context);
                    case _NoLoginOverflowAction.playRecord:
                      const PlayRecordRoute().push(context);
                  }
                },
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
              Consumer(
                builder: (context, ref, _) {
                  final isAuthorizing = ref.watch(userControllerProvider).isAuthorizing;
                  final myController = ref.read(userControllerProvider.notifier);
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isAuthorizing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: null,
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
                                      child: CircularProgressIndicator(
                                          strokeWidth: 3),
                                    ),
                                    SizedBox(width: 8),
                                    Text('正在等待登录结果'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              SizedBox(
                                width: 76,
                                child: OutlinedButton(
                                  onPressed: isAuthorizing
                                      ? myController.cancelOAuthWaiting
                                      : null,
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
                                    side: const BorderSide(
                                        color: Colors.transparent),
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
                            onPressed: () => const LoginRoute().push(context),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 10),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('账号密码登录'),
                          ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  return TextButton(
                    onPressed: () =>
                        ref.read(userControllerProvider.notifier).openOAuthPage(),
                    child: const Text(
                      '使用 Bangumi 授权登录',
                      style: TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
              TextButton(
                onPressed: () => const RegisterRoute().push(context),
                child: const Text(
                  '还没有账号？点击注册',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              Text(
                '如果无法登录请使用代理改善网络',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              )
            ],
          ),
        )
      ],
    );
  }
}

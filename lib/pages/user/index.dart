import 'package:anime_flow/pages/user/user_view/user_view.dart';
import 'package:anime_flow/providers/user/user_controller.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/widget/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserPage extends ConsumerWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<dynamic>>(currentUserInfoProvider, (previous, next) {
      final shouldNotifyNull =
          next is AsyncData && next.value == null && previous?.value != null;
      final shouldNotifyError = next is AsyncError;
      if (!shouldNotifyNull && !shouldNotifyError) {
        return;
      }

      final message = shouldNotifyError ? '获取用户资料失败' : '用户资料已失效';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        NotificationToast.show('提示', message, align: Alignment.topCenter);
      });
    });

    final userInfoAsync = ref.watch(currentUserInfoProvider);
    return userInfoAsync.when(
      data: (userInfo) => userInfo == null
          ? const Scaffold(
              body: Center(child: Text('暂无用户资料')),
            )
          : Scaffold(body: UserView(user: userInfo)),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('获取用户资料失败'),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => ref.invalidate(currentUserInfoProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('确认退出'),
                          content: const Text('确定要退出登录吗？'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await ref
                            .read(userControllerProvider.notifier)
                            .clearUserInfo();
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('退出登录'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

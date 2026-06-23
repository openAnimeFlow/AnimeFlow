import 'package:anime_flow/pages/user/user_view/user_view.dart';
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
          child: InkWell(
            onTap: () => ref.invalidate(currentUserInfoProvider),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  Text('获取用户资料失败'),
                  Icon(Icons.refresh),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

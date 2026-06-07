import 'package:anime_flow/pages/login/index.dart';
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
      final isLoggedIn = ref.read(isLoggedInProvider).value ?? false;
      if (!isLoggedIn) {
        return;
      }

      final shouldNotifyNull =
          next is AsyncData && next.value == null && previous?.value != null;
      final shouldNotifyError = next is AsyncError;
      if (!shouldNotifyNull && !shouldNotifyError) {
        return;
      }

      final message = shouldNotifyError ? '获取用户资料失败，请重新登录' : '登录状态已失效，请重新登录';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        NotificationToast.show('提示', message);
      });
    });

    final isLoggedInAsync = ref.watch(isLoggedInProvider);
    final userInfoAsync = ref.watch(currentUserInfoProvider);
    return isLoggedInAsync.when(
      data: (isLoggedIn) {
        if (!isLoggedIn) {
          return const Scaffold(body: LoginPage());
        }
        return userInfoAsync.when(
          data: (userInfo) => userInfo == null
              ? const Scaffold(body: LoginPage())
              : Scaffold(body: UserView(userInfoItem: userInfo)),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Scaffold(body: LoginPage()),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(body: LoginPage()),
    );
  }

}
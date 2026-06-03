import 'package:anime_flow/features/my/my_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_view/login_view.dart';
import 'no_login/no_login_view.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final userInfo = ref.watch(currentUserInfoProvider);
        return userInfo == null
            ? const Scaffold(body: NoLoginView())
            : Scaffold(
                body: LoginView(userInfoItem: userInfo),
              );
      },
    );
  }
}

import 'package:anime_flow/features/my/my_state_provider.dart';
import 'package:anime_flow/pages/login/index.dart';
import 'package:anime_flow/pages/user/user_view/user_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'no_login/no_login_view.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final userInfo = ref.watch(currentUserInfoProvider);
        return userInfo == null
            ? const Scaffold(body: LoginPage())
            : Scaffold(
                body: UserView(userInfoItem: userInfo),
              );
      },
    );
  }
}

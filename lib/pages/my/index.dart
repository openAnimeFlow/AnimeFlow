import 'package:anime_flow/pages/my/login_view/login_view.dart';
import 'package:anime_flow/pages/my/no_login/no_login_view.dart';
import 'package:anime_flow/providers/my_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final userInfo = ref.watch(myProvider).userInfo;
        if (userInfo == null) {
          return const Scaffold(body: NoLoginView());
        }
        return Scaffold(
          body: LoginView(userInfoItem: userInfo),
        );
      },
    );
  }
}

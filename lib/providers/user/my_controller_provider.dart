import 'package:anime_flow/providers/user/my_controller.dart';
import 'package:anime_flow/providers/user/my_state_provider.dart';
import 'package:anime_flow/http/interceptors/bgm_refresh_token_interceptor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_controller_provider.g.dart';

@Riverpod(keepAlive: true)
MyController myController(Ref ref) {
  BgmRefreshTokenInterceptor.onSessionExpired = () {
    ref.read(currentUserInfoProvider.notifier).clear();
  };

  final controller = MyController(ref);
  Future.microtask(controller.init);
  return controller;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_service.dart';
import 'session_provider.dart';
import 'token_providers.dart';

final loginServiceProvider = Provider((ref) => LoginService(
      flowTokenRepository: ref.watch(flowTokenRepositoryProvider),
    ));

/// A successful login updates the session even if its page has been closed.
final emailLoginProvider = Provider((ref) {
  final service = ref.watch(loginServiceProvider);
  return ({required String email, required String password}) async {
    final container = ref.container;
    final token = await service.login(email: email, password: password);
    container.read(authSessionRevisionProvider.notifier).changed();
    container.invalidate(currentFlowTokenProvider);
    container.invalidate(isLoggedInProvider);
    return token;
  };
});

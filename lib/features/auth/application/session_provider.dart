import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/network/interceptors/flow_refresh_token_interceptor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Notifier, NotifierProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'token_providers.dart';

part 'session_provider.g.dart';

/// Identity changes are separate from access-token renewal.
final authSessionRevisionProvider =
    NotifierProvider<AuthRevision, int>(AuthRevision.new);
final bangumiBindingRevisionProvider =
    NotifierProvider<AuthRevision, int>(AuthRevision.new);

class AuthRevision extends Notifier<int> {
  @override
  int build() => 0;
  void changed() => state++;
}

void invalidateAuthSession(Ref ref) {
  final container = ref.container;
  // Synchronously clear user state before any pending request can complete.
  container.read(authSessionRevisionProvider.notifier).changed();
  container.invalidate(currentFlowTokenProvider);
  container.invalidate(isLoggedInProvider);
}

@Riverpod(keepAlive: true)
class CurrentFlowToken extends _$CurrentFlowToken {
  @override
  Future<FlowToken?> build() async {
    void expired() {
      if (ref.mounted) invalidateAuthSession(ref);
    }

    void refreshed() {
      if (ref.mounted) ref.invalidateSelf();
    }

    FlowRefreshTokenInterceptor.onSessionExpired = expired;
    FlowRefreshTokenInterceptor.onTokenRefreshed = refreshed;
    ref.onDispose(() {
      if (identical(FlowRefreshTokenInterceptor.onSessionExpired, expired)) {
        FlowRefreshTokenInterceptor.onSessionExpired = null;
      }
      if (identical(FlowRefreshTokenInterceptor.onTokenRefreshed, refreshed)) {
        FlowRefreshTokenInterceptor.onTokenRefreshed = null;
      }
    });
    return ref.watch(flowTokenRepositoryProvider).getToken();
  }
}

@Riverpod(keepAlive: true)
Future<bool> isLoggedIn(Ref ref) async =>
    await ref.watch(currentFlowTokenProvider.future) != null;

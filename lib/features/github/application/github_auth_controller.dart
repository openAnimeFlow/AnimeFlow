import 'dart:async';

import 'package:anime_flow/core/auth/repository/github_token_storage.dart';
import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/features/github/data/github_auth_api.dart';
import 'package:anime_flow/features/github/application/github_token_manager.dart';
import 'package:anime_flow/features/github/domain/github_auth_models.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_auth_controller.g.dart';

enum GitHubAuthPhase {
  loading,
  signedOut,
  requesting,
  waiting,
  connected,
  failed
}

class GitHubAuthState {
  const GitHubAuthState(this.phase, {this.session, this.user, this.error});

  final GitHubAuthPhase phase;
  final GitHubDeviceSession? session;
  final GitHubUser? user;
  final String? error;
}

@Riverpod(keepAlive: true)
GitHubAuthApi gitHubAuthApi(Ref ref) => GitHubAuthApiImpl();

@Riverpod(keepAlive: true)
TokenRepository<GitHubToken> gitHubTokenRepository(Ref ref) =>
    GitHubTokenStorage.instance;

@Riverpod(keepAlive: true)
GitHubTokenManager gitHubTokenManager(Ref ref) => GitHubTokenManager(
      ref.read(gitHubTokenRepositoryProvider),
      ref.read(gitHubAuthApiProvider),
    );

@Riverpod(keepAlive: true)
class GitHubAuthController extends _$GitHubAuthController {
  int _generation = 0;
  bool _busy = false;
  Timer? _refreshTimer;

  @override
  GitHubAuthState build() {
    ref.onDispose(() {
      _generation++;
      _refreshTimer?.cancel();
    });
    unawaited(_restore());
    return const GitHubAuthState(GitHubAuthPhase.loading);
  }

  Future<void> _restore() async {
    final generation = _generation;
    try {
      final token = await ref.read(gitHubTokenRepositoryProvider).getToken();
      if (generation != _generation) return;
      if (token == null) {
        state = const GitHubAuthState(GitHubAuthPhase.signedOut);
        return;
      }
      var usableToken =
          await ref.read(gitHubTokenManagerProvider).refreshIfNeeded();
      if (generation != _generation) return;
      GitHubUser user;
      try {
        user = await ref
            .read(gitHubAuthApiProvider)
            .getCurrentUser(usableToken.accessToken);
      } on DioException catch (error) {
        if (error.response?.statusCode != 401) rethrow;
        usableToken = await ref
            .read(gitHubTokenManagerProvider)
            .refreshIfNeeded(force: true);
        try {
          user = await ref
              .read(gitHubAuthApiProvider)
              .getCurrentUser(usableToken.accessToken);
        } on DioException catch (retryError) {
          if (retryError.response?.statusCode != 401) rethrow;
          await ref.read(gitHubTokenManagerProvider).clear();
          throw const GitHubReauthorizationRequired();
        }
      }
      if (generation == _generation) {
        state = GitHubAuthState(GitHubAuthPhase.connected, user: user);
        _scheduleRefresh(usableToken, generation);
      }
    } on GitHubReauthorizationRequired {
      if (generation == _generation) {
        state = const GitHubAuthState(GitHubAuthPhase.failed,
            error: 'GitHub 授权已失效，请重新授权');
      }
    } catch (_) {
      if (generation == _generation) {
        state = const GitHubAuthState(GitHubAuthPhase.failed,
            error: '读取 GitHub 授权状态失败，请重试');
      }
    }
  }

  Future<GitHubDeviceSession?> start() async {
    if (_busy ||
        state.phase == GitHubAuthPhase.waiting ||
        state.phase == GitHubAuthPhase.requesting) {
      return null;
    }
    _busy = true;
    final generation = ++_generation;
    _refreshTimer?.cancel();
    state = const GitHubAuthState(GitHubAuthPhase.requesting);
    try {
      final session = await ref.read(gitHubAuthApiProvider).requestDeviceCode();
      if (generation != _generation) return null;
      state = GitHubAuthState(GitHubAuthPhase.waiting, session: session);
      unawaited(_poll(session, generation));
      return session;
    } catch (error) {
      if (generation == _generation) {
        state = GitHubAuthState(GitHubAuthPhase.failed,
            error: resolveAnimeFlowErrorMessage(error,
                fallback: '获取 GitHub 授权码失败，请重试'));
      }
      return null;
    } finally {
      _busy = false;
    }
  }

  Future<void> _poll(GitHubDeviceSession session, int generation) async {
    var interval = session.intervalSeconds;
    while (generation == _generation &&
        DateTime.now().isBefore(session.expiresAt)) {
      await Future<void>.delayed(Duration(seconds: interval));
      if (generation != _generation) return;
      if (!DateTime.now().isBefore(session.expiresAt)) break;
      GitHubToken? savedToken;
      try {
        final result = await ref
            .read(gitHubAuthApiProvider)
            .exchangeDeviceCode(session.deviceCode);
        if (generation != _generation) return;
        switch (result.status) {
          case 'authorization_pending':
            continue;
          case 'slow_down':
            interval = result.intervalSeconds != null &&
                    result.intervalSeconds! > interval
                ? result.intervalSeconds!
                : interval + 5;
            continue;
          case 'success':
            final token = result.token!;
            await ref.read(gitHubTokenRepositoryProvider).saveToken(token);
            savedToken = token;
            if (generation != _generation) {
              await _discardStaleToken(token);
              return;
            }
            final user = await ref
                .read(gitHubAuthApiProvider)
                .getCurrentUser(token.accessToken);
            if (generation == _generation) {
              state = GitHubAuthState(GitHubAuthPhase.connected, user: user);
              _scheduleRefresh(token, generation);
            } else {
              await _discardStaleToken(token);
            }
            return;
          case 'access_denied':
            state = const GitHubAuthState(GitHubAuthPhase.failed,
                error: 'GitHub 授权已被拒绝');
            return;
          case 'expired_token':
            state = const GitHubAuthState(GitHubAuthPhase.failed,
                error: 'GitHub 授权码已过期，请重试');
            return;
          default:
            state = const GitHubAuthState(GitHubAuthPhase.failed,
                error: 'GitHub 授权失败，请重试');
            return;
        }
      } catch (error) {
        if (generation == _generation) {
          state = GitHubAuthState(GitHubAuthPhase.failed,
              error: resolveAnimeFlowErrorMessage(error,
                  fallback: 'GitHub 授权请求失败，请重试'));
        } else if (savedToken != null) {
          await _discardStaleToken(savedToken);
        }
        return;
      }
    }
    if (generation == _generation) {
      state = const GitHubAuthState(GitHubAuthPhase.failed,
          error: 'GitHub 授权码已过期，请重试');
    }
  }

  void _scheduleRefresh(GitHubToken token, int generation) {
    _refreshTimer?.cancel();
    if (generation != _generation) return;
    final delay = token.accessExpiresAt
        .difference(DateTime.now().add(GitHubTokenManager.refreshBeforeExpiry));
    _refreshTimer = Timer(delay.isNegative ? Duration.zero : delay,
        () => unawaited(_refreshInBackground(generation)));
  }

  Future<void> _refreshInBackground(int generation) async {
    try {
      final token =
          await ref.read(gitHubTokenManagerProvider).refreshIfNeeded();
      if (generation != _generation) return;
      state = GitHubAuthState(GitHubAuthPhase.connected, user: state.user);
      _scheduleRefresh(token, generation);
    } on GitHubReauthorizationRequired {
      if (generation == _generation) {
        state = const GitHubAuthState(GitHubAuthPhase.failed,
            error: 'GitHub 授权已失效，请重新授权');
      }
    } catch (_) {
      if (generation != _generation) return;
      state = GitHubAuthState(GitHubAuthPhase.connected,
          user: state.user, error: 'GitHub 授权刷新暂时失败，将自动重试');
      _refreshTimer = Timer(const Duration(minutes: 1),
          () => unawaited(_refreshInBackground(generation)));
    }
  }

  Future<void> _discardStaleToken(GitHubToken token) async {
    final repository = ref.read(gitHubTokenRepositoryProvider);
    final saved = await repository.getToken();
    if (saved?.accessToken == token.accessToken) {
      await repository.removeToken();
    }
  }

  void cancel() {
    if (state.phase != GitHubAuthPhase.waiting &&
        state.phase != GitHubAuthPhase.requesting) {
      return;
    }
    _generation++;
    state = const GitHubAuthState(GitHubAuthPhase.signedOut);
  }

  Future<void> disconnect() async {
    _generation++;
    _refreshTimer?.cancel();
    await ref.read(gitHubTokenManagerProvider).clear();
    state = const GitHubAuthState(GitHubAuthPhase.signedOut);
  }

  Future<void> retryRestore() async {
    state = const GitHubAuthState(GitHubAuthPhase.loading);
    await _restore();
  }
}

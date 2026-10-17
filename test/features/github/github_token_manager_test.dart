import 'dart:async';

import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:anime_flow/features/github/application/github_token_manager.dart';
import 'package:anime_flow/features/github/data/github_auth_api.dart';
import 'package:anime_flow/features/github/domain/github_auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tokens implements TokenRepository<GitHubToken> {
  _Tokens(this.value);

  GitHubToken? value;

  @override
  Future<GitHubToken?> getToken() async => value;

  @override
  Future<void> saveToken(GitHubToken token) async => value = token;

  @override
  Future<void> removeToken() async => value = null;
}

class _Api implements GitHubAuthApi {
  _Api(this.onRefresh);

  Future<GitHubToken> Function(String) onRefresh;
  int refreshCalls = 0;

  @override
  Future<GitHubToken> refreshToken(String refreshToken) {
    refreshCalls++;
    return onRefresh(refreshToken);
  }

  @override
  Future<GitHubDeviceSession> requestDeviceCode() => throw UnimplementedError();

  @override
  Future<GitHubExchangeResult> exchangeDeviceCode(String deviceCode) =>
      throw UnimplementedError();

  @override
  Future<GitHubUser> getCurrentUser(String accessToken) =>
      throw UnimplementedError();
}

GitHubToken _token(DateTime now, String suffix,
        {Duration accessLife = const Duration(minutes: 1),
        Duration refreshLife = const Duration(days: 10)}) =>
    GitHubToken(
      accessToken: 'access-$suffix',
      refreshToken: 'refresh-$suffix',
      accessExpiresAt: now.add(accessLife),
      refreshExpiresAt: now.add(refreshLife),
      tokenType: 'bearer',
    );

void main() {
  test('concurrent requests share one refresh and persist both rotated tokens',
      () async {
    final now = DateTime.utc(2026, 9, 26);
    final store = _Tokens(_token(now, 'old'));
    final rotated = _token(now, 'new', accessLife: const Duration(hours: 8));
    final response = Completer<GitHubToken>();
    final api = _Api((_) => response.future);
    final manager = GitHubTokenManager(store, api, now: () => now);

    final requests = List.generate(3, (_) => manager.refreshIfNeeded());
    await Future<void>.delayed(Duration.zero);
    expect(api.refreshCalls, 1);
    response.complete(rotated);
    final results = await Future.wait(requests);
    expect(results.every((token) => token.accessToken == rotated.accessToken),
        isTrue);
    expect(store.value?.refreshToken, rotated.refreshToken);

    final reopened = GitHubTokenManager(store, api, now: () => now);
    expect((await reopened.refreshIfNeeded()).accessToken, rotated.accessToken);
    expect(api.refreshCalls, 1);
  });

  test('bad refresh token clears saved credentials', () async {
    final now = DateTime.utc(2026, 9, 26);
    final store = _Tokens(_token(now, 'old'));
    final api = _Api((_) async => throw const GitHubRefreshInvalidException());
    final manager = GitHubTokenManager(store, api, now: () => now);

    await expectLater(manager.refreshIfNeeded(),
        throwsA(isA<GitHubReauthorizationRequired>()));
    expect(store.value, isNull);
  });

  test('network failure retains credentials for retry', () async {
    final now = DateTime.utc(2026, 9, 26);
    final original = _token(now, 'old');
    final store = _Tokens(original);
    final api = _Api((_) async => throw Exception('network unavailable'));
    final manager = GitHubTokenManager(store, api, now: () => now);

    await expectLater(manager.refreshIfNeeded(), throwsException);
    expect(store.value?.refreshToken, original.refreshToken);

    api.onRefresh =
        (_) async => _token(now, 'new', accessLife: const Duration(hours: 8));
    expect((await manager.refreshIfNeeded()).refreshToken, 'refresh-new');
  });

  test('disconnect while refreshing cannot restore credentials', () async {
    final now = DateTime.utc(2026, 9, 26);
    final store = _Tokens(_token(now, 'old'));
    final response = Completer<GitHubToken>();
    final api = _Api((_) => response.future);
    final manager = GitHubTokenManager(store, api, now: () => now);

    final refreshing = manager.refreshIfNeeded();
    final expectation =
        expectLater(refreshing, throwsA(isA<GitHubReauthorizationRequired>()));
    await Future<void>.delayed(Duration.zero);
    final clearing = manager.clear();
    response.complete(_token(now, 'new'));
    await expectation;
    await clearing;
    expect(store.value, isNull);
  });

  test('expired refresh token requires a new authorization', () async {
    final now = DateTime.utc(2026, 9, 26);
    final store =
        _Tokens(_token(now, 'old', refreshLife: const Duration(seconds: -1)));
    final api = _Api((_) async => throw UnimplementedError());
    final manager = GitHubTokenManager(store, api, now: () => now);

    await expectLater(manager.refreshIfNeeded(),
        throwsA(isA<GitHubReauthorizationRequired>()));
    expect(api.refreshCalls, 0);
    expect(store.value, isNull);
  });
}

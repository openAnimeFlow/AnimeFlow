import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:anime_flow/features/github/application/github_auth_controller.dart';
import 'package:anime_flow/features/github/data/github_auth_api.dart';
import 'package:anime_flow/features/github/domain/github_auth_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _Tokens implements TokenRepository<GitHubToken> {
  _Tokens([this.value]);

  GitHubToken? value;

  @override
  Future<GitHubToken?> getToken() async => value;

  @override
  Future<void> saveToken(GitHubToken token) async => value = token;

  @override
  Future<void> removeToken() async => value = null;
}

class _Api implements GitHubAuthApi {
  int exchanges = 0;
  int refreshCalls = 0;
  String? lastUserToken;
  String? unauthorizedAccessToken;
  GitHubToken? rotatedToken;
  GitHubExchangeResult result = GitHubExchangeResult.fromJson({
    'status': 'success',
    'accessToken': 'access',
    'refreshToken': 'refresh',
    'expiresIn': 3600,
    'refreshTokenExpiresIn': 7200,
    'tokenType': 'bearer',
  }, DateTime.now());

  @override
  Future<GitHubDeviceSession> requestDeviceCode() async => GitHubDeviceSession(
        deviceCode: 'device',
        userCode: 'ABCD-EFGH',
        verificationUri: Uri.parse('https://github.com/login/device'),
        expiresAt: DateTime.now().add(const Duration(seconds: 10)),
        intervalSeconds: 1,
      );

  @override
  Future<GitHubExchangeResult> exchangeDeviceCode(String deviceCode) async {
    exchanges++;
    return result;
  }

  @override
  Future<GitHubUser> getCurrentUser(String accessToken) async {
    lastUserToken = accessToken;
    if (accessToken == unauthorizedAccessToken) {
      final options = RequestOptions(path: '/user');
      throw DioException.badResponse(
        statusCode: 401,
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      );
    }
    return const GitHubUser(id: 7, login: 'tester');
  }

  @override
  Future<GitHubToken> refreshToken(String refreshToken) async {
    refreshCalls++;
    return rotatedToken!;
  }
}

void main() {
  test('a rejected access token is refreshed and the user request retried',
      () async {
    final now = DateTime.now();
    final tokens = _Tokens(GitHubToken(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
      accessExpiresAt: now.add(const Duration(hours: 8)),
      refreshExpiresAt: now.add(const Duration(days: 10)),
      tokenType: 'bearer',
    ));
    final api = _Api()
      ..unauthorizedAccessToken = 'old-access'
      ..rotatedToken = GitHubToken(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
        accessExpiresAt: now.add(const Duration(hours: 8)),
        refreshExpiresAt: now.add(const Duration(days: 10)),
        tokenType: 'bearer',
      );
    final container = ProviderContainer(overrides: [
      gitHubTokenRepositoryProvider.overrideWithValue(tokens),
      gitHubAuthApiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    container.read(gitHubAuthControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(api.refreshCalls, 1);
    expect(api.lastUserToken, 'new-access');
    expect(tokens.value?.refreshToken, 'new-refresh');
    expect(container.read(gitHubAuthControllerProvider).phase,
        GitHubAuthPhase.connected);
  });

  test('restoring a near-expiry session refreshes before loading the user',
      () async {
    final now = DateTime.now();
    final tokens = _Tokens(GitHubToken(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
      accessExpiresAt: now.add(const Duration(minutes: 1)),
      refreshExpiresAt: now.add(const Duration(days: 10)),
      tokenType: 'bearer',
    ));
    final api = _Api()
      ..rotatedToken = GitHubToken(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
        accessExpiresAt: now.add(const Duration(hours: 8)),
        refreshExpiresAt: now.add(const Duration(days: 10)),
        tokenType: 'bearer',
      );
    final container = ProviderContainer(overrides: [
      gitHubTokenRepositoryProvider.overrideWithValue(tokens),
      gitHubAuthApiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    container.read(gitHubAuthControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(api.refreshCalls, 1);
    expect(api.lastUserToken, 'new-access');
    expect(tokens.value?.refreshToken, 'new-refresh');
    expect(container.read(gitHubAuthControllerProvider).phase,
        GitHubAuthPhase.connected);
  });

  test('connected session refreshes before access token expiry', () async {
    final now = DateTime.now();
    final tokens = _Tokens(GitHubToken(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
      accessExpiresAt: now.add(const Duration(minutes: 5, seconds: 1)),
      refreshExpiresAt: now.add(const Duration(days: 10)),
      tokenType: 'bearer',
    ));
    final api = _Api()
      ..rotatedToken = GitHubToken(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
        accessExpiresAt: now.add(const Duration(hours: 8)),
        refreshExpiresAt: now.add(const Duration(days: 10)),
        tokenType: 'bearer',
      );
    final container = ProviderContainer(overrides: [
      gitHubTokenRepositoryProvider.overrideWithValue(tokens),
      gitHubAuthApiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    container.read(gitHubAuthControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    container.read(gitHubAuthControllerProvider.notifier).cancel();
    await Future<void>.delayed(const Duration(milliseconds: 1300));

    expect(api.refreshCalls, 1);
    expect(tokens.value?.refreshToken, 'new-refresh');
    expect(container.read(gitHubAuthControllerProvider).phase,
        GitHubAuthPhase.connected);
  });

  test('device authorization saves token and loads GitHub user', () async {
    final tokens = _Tokens();
    final api = _Api();
    final container = ProviderContainer(overrides: [
      gitHubTokenRepositoryProvider.overrideWithValue(tokens),
      gitHubAuthApiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    container.read(gitHubAuthControllerProvider);
    await Future<void>.delayed(Duration.zero);

    final session =
        await container.read(gitHubAuthControllerProvider.notifier).start();
    expect(session?.userCode, 'ABCD-EFGH');
    expect(container.read(gitHubAuthControllerProvider).phase,
        GitHubAuthPhase.waiting);
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(api.exchanges, 1);
    expect(tokens.value?.accessToken, 'access');
    expect(container.read(gitHubAuthControllerProvider).user?.login, 'tester');
  });

  test('cancelling authorization prevents token exchange', () async {
    final tokens = _Tokens();
    final api = _Api();
    final container = ProviderContainer(overrides: [
      gitHubTokenRepositoryProvider.overrideWithValue(tokens),
      gitHubAuthApiProvider.overrideWithValue(api),
    ]);
    addTearDown(container.dispose);
    container.read(gitHubAuthControllerProvider);
    await Future<void>.delayed(Duration.zero);

    await container.read(gitHubAuthControllerProvider.notifier).start();
    container.read(gitHubAuthControllerProvider.notifier).cancel();
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(api.exchanges, 0);
    expect(tokens.value, isNull);
    expect(container.read(gitHubAuthControllerProvider).phase,
        GitHubAuthPhase.signedOut);
  });
}

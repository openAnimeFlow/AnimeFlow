import 'package:anime_flow/models/item/flow/flow_token.dart';
import 'package:anime_flow/pages/login/service/login_service.dart';
import 'package:anime_flow/repository/token_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFlowTokenRepository implements TokenRepository<FlowToken> {
  FlowToken? saved;

  @override
  Future<FlowToken?> getToken() async => saved;

  @override
  Future<void> removeToken() async {
    saved = null;
  }

  @override
  Future<void> saveToken(FlowToken token) async {
    saved = token;
  }
}

FlowToken _token() {
  return FlowToken(
    accessToken: 'access',
    refreshToken: 'refresh',
    tokenType: 'Bearer',
    expiresIn: 3600,
    refreshExpiresIn: 86400,
    sessionId: 'session',
  );
}

void main() {
  group('LoginService', () {
    test('login persists token from email login API', () async {
      final repository = _FakeFlowTokenRepository();
      var loginCalled = false;

      final service = LoginService(
        flowTokenRepository: repository,
        emailLogin: ({
          required String email,
          required String password,
          required String platform,
        }) async {
          loginCalled = true;
          expect(email, 'user@example.com');
          expect(password, 'secret');
          expect(platform, isNotEmpty);
          return _token();
        },
      );

      final token = await service.login(
        email: 'user@example.com',
        password: 'secret',
      );

      expect(loginCalled, isTrue);
      expect(token.accessToken, 'access');
      expect(repository.saved?.refreshToken, 'refresh');
    });
  });
}

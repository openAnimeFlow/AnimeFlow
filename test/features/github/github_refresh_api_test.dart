import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/features/github/data/github_auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('device-flow refresh sends no client secret and parses rotated tokens',
      () async {
    final dio = Dio(BaseOptions(baseUrl: GitHubApi.oauthBaseUrl));
    late RequestOptions captured;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      captured = options;
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'access_token': 'access-new',
          'refresh_token': 'refresh-new',
          'expires_in': 28800,
          'refresh_token_expires_in': 15897600,
          'token_type': 'bearer',
        },
      ));
    }));
    final api = GitHubAuthApiImpl(oauthDio: dio, clientId: 'Iv1.test');

    final token = await api.refreshToken('refresh-old');

    expect(captured.uri.toString(),
        '${GitHubApi.oauthBaseUrl}${GitHubApi.accessToken}');
    expect(captured.contentType, Headers.formUrlEncodedContentType);
    expect(captured.headers['Accept'], 'application/json');
    expect(captured.data, {
      'client_id': 'Iv1.test',
      'grant_type': 'refresh_token',
      'refresh_token': 'refresh-old',
    });
    expect(token.accessToken, 'access-new');
    expect(token.refreshToken, 'refresh-new');
    expect(token.accessExpiresAt.isAfter(DateTime.now()), isTrue);
  });

  test('bad_refresh_token requests reauthorization', () async {
    final dio = Dio(BaseOptions(baseUrl: GitHubApi.oauthBaseUrl));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'error': 'bad_refresh_token'},
      ));
    }));
    final api = GitHubAuthApiImpl(oauthDio: dio, clientId: 'Iv1.test');

    await expectLater(api.refreshToken('invalid'),
        throwsA(isA<GitHubRefreshInvalidException>()));
  });

  test('bad_refresh_token in an HTTP error also requests reauthorization',
      () async {
    final dio = Dio(BaseOptions(baseUrl: GitHubApi.oauthBaseUrl));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final response = Response(
        requestOptions: options,
        statusCode: 400,
        data: {'error': 'bad_refresh_token'},
      );
      handler.reject(DioException.badResponse(
        statusCode: 400,
        requestOptions: options,
        response: response,
      ));
    }));
    final api = GitHubAuthApiImpl(oauthDio: dio, clientId: 'Iv1.test');

    await expectLater(api.refreshToken('invalid'),
        throwsA(isA<GitHubRefreshInvalidException>()));
  });
}

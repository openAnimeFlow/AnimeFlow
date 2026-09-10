import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/core/network_exception.dart';
import 'package:anime_flow/core/network/interceptors/flow_refresh_token_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

FlowToken token(String value) => FlowToken(
    accessToken: value,
    refreshToken: 'refresh-$value',
    tokenType: 'Bearer',
    expiresIn: 7200,
    refreshExpiresIn: 604800,
    sessionId: 'session');

class Repository implements TokenRepository<FlowToken> {
  FlowToken? value = token('old');
  int removals = 0;
  @override
  Future<FlowToken?> getToken() async {
    // Reproduce the asynchronous secure-storage read race.
    await Future<void>.delayed(Duration.zero);
    return value;
  }

  @override
  Future<void> saveToken(FlowToken token) async {
    value = token;
  }

  @override
  Future<void> removeToken() async {
    removals++;
    value = null;
  }
}

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody reply(int code, {int status = 200}) =>
    ResponseBody.fromString(jsonEncode({'code': code}), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });

void main() {
  tearDown(() {
    FlowRefreshTokenInterceptor.onSessionExpired = null;
    FlowRefreshTokenInterceptor.onTokenRefreshed = null;
  });

  Dio client(Repository repository, RefreshFlowToken refresh,
      FutureOr<ResponseBody> Function(RequestOptions) respond) {
    final dio = Dio();
    dio.httpClientAdapter = Adapter(respond);
    dio.interceptors.add(
        FlowRefreshTokenInterceptor(dio, repository, refreshToken: refresh));
    addTearDown(() => dio.close(force: true));
    return dio;
  }

  Future<Response<dynamic>> request(Dio dio) =>
      dio.get<dynamic>('https://example.test/api/v1/users/me',
          options: Options(headers: {Constants.authorization: 'Bearer old'}));

  for (final reason in ['bangumi_auth_required', 'api_signature_invalid']) {
    for (final status in [200, 401]) {
      test('does not refresh for $reason with HTTP $status', () async {
        final repository = Repository();
        var refreshes = 0;
        final dio = client(repository, ({required refreshToken}) async {
          refreshes++;
          return token('new');
        },
            (_) => ResponseBody.fromString(
                    jsonEncode({'code': 401, 'authReason': reason}), status,
                    headers: {
                      Headers.contentTypeHeader: [Headers.jsonContentType]
                    }));
        if (status == 401) {
          await expectLater(request(dio), throwsA(isA<DioException>()));
        } else {
          expect((await request(dio)).data['code'], 401);
        }
        expect(refreshes, 0);
        expect(repository.removals, 0);
      });
    }
  }

  test('explicit refresh failure reason does not depend on error wording',
      () async {
    final repository = Repository();
    final dio = client(repository, ({required refreshToken}) async {
      throw const AnimeFlowApiException(
          code: 401,
          message: 'Refresh rejected',
          authReason: 'refresh_token_invalid');
    }, (_) => reply(401));
    await request(dio);
    expect(repository.removals, 1);
  });

  test('concurrent 401s share refresh before asynchronous storage reads',
      () async {
    final repository = Repository();
    var refreshes = 0;
    final dio = client(repository, ({required refreshToken}) async {
      refreshes++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return token('new');
    },
        (options) => reply(
            options.headers[Constants.authorization] == 'Bearer new'
                ? 200
                : 401));
    final responses = await Future.wait(List.generate(10, (_) => request(dio)));
    expect(responses.every((r) => r.data['code'] == 200), isTrue);
    expect(refreshes, 1);
    expect(repository.removals, 0);
    expect(repository.value?.refreshToken, 'refresh-new');
  });

  test('late 401 uses the latest token without refreshing again', () async {
    final repository = Repository()..value = token('new');
    var refreshes = 0;
    final dio = client(repository, ({required refreshToken}) async {
      refreshes++;
      return token('unexpected');
    },
        (options) => reply(
            options.headers[Constants.authorization] == 'Bearer new'
                ? 200
                : 401));
    expect((await request(dio)).data['code'], 200);
    expect(refreshes, 0);
  });

  for (final http401 in [false, true]) {
    test('persistent ${http401 ? 'HTTP' : 'business'} 401 retries only once',
        () async {
      final repository = Repository();
      var requests = 0;
      var refreshes = 0;
      final dio = client(repository, ({required refreshToken}) async {
        refreshes++;
        return token('new');
      }, (_) {
        requests++;
        return reply(401, status: http401 ? 401 : 200);
      });
      if (http401) {
        await expectLater(request(dio), throwsA(isA<DioException>()));
      } else {
        expect((await request(dio)).data['code'], 401);
      }
      expect(requests, 2);
      expect(refreshes, 1);
      expect(repository.value?.accessToken, 'new');
      expect(repository.removals, 0);
    });
  }

  for (final error in <Object>[
    const NetworkException(
        type: NetworkExceptionType.receiveTimeout, message: 'timeout'),
    const NetworkException(
        type: NetworkExceptionType.badResponse,
        message: 'limit',
        statusCode: 429),
    const AnimeFlowApiException(code: 500, message: 'server error'),
    const AnimeFlowApiException(code: 401, message: '未授权'),
    const FormatException('invalid response'),
  ]) {
    test('refresh failure preserves credentials: $error', () async {
      final repository = Repository();
      final dio = client(repository,
          ({required refreshToken}) async => throw error, (_) => reply(401));
      expect((await request(dio)).data['code'], 401);
      expect(repository.value?.accessToken, 'old');
      expect(repository.removals, 0);
    });
  }

  test('confirmed invalid refresh clears credentials exactly once', () async {
    final repository = Repository();
    var expired = 0;
    FlowRefreshTokenInterceptor.onSessionExpired = () {
      expired++;
    };
    final dio = client(repository, ({required refreshToken}) async {
      throw const AnimeFlowApiException(code: 401, message: '刷新令牌无效或已过期');
    }, (_) => reply(401));
    await request(dio);
    expect(repository.value, isNull);
    expect(repository.removals, 1);
    expect(expired, 1);
  });

  for (final invalid in [false, true]) {
    test('old refresh cannot overwrite or clear a new login ($invalid)',
        () async {
      final repository = Repository();
      final started = Completer<void>();
      final result = Completer<FlowToken>();
      final dio = client(repository, ({required refreshToken}) {
        started.complete();
        return result.future;
      }, (_) => reply(401));
      final pending = request(dio);
      await started.future;
      await repository.saveToken(token('other-login'));
      if (invalid) {
        result.completeError(
            const AnimeFlowApiException(code: 401, message: '刷新令牌无效或已过期'));
      } else {
        result.complete(token('new'));
      }
      await pending;
      expect(repository.value?.accessToken, 'other-login');
      expect(repository.removals, 0);
    });
  }

  test('logout while refreshing cannot restore the session', () async {
    final repository = Repository();
    final started = Completer<void>();
    final result = Completer<FlowToken>();
    final dio = client(repository, ({required refreshToken}) {
      started.complete();
      return result.future;
    }, (_) => reply(401));
    final pending = request(dio);
    await started.future;
    FlowRefreshTokenInterceptor.invalidatePendingRefresh(repository);
    await repository.removeToken();
    result.complete(token('new'));
    await pending;
    expect(repository.value, isNull);
    expect(repository.removals, 1);
  });
}

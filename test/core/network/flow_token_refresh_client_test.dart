import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/auth/repository/flow_token_storage.dart';
import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/clients/flow_token_refresh_client.dart';
import 'package:anime_flow/core/network/core/api_signature.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/network/core/network_exception.dart';
import 'package:anime_flow/core/network/interceptors/flow_refresh_token_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

FlowToken token(String access) => FlowToken(
    accessToken: access,
    refreshToken: 'refresh-$access',
    tokenType: 'Bearer',
    expiresIn: 3600,
    refreshExpiresIn: 86400,
    sessionId: 'session');

ResponseBody envelope(Object? data,
        {int code = 200, int status = 200, String? reason}) =>
    ResponseBody.fromString(
        jsonEncode({
          'code': code,
          'data': data,
          if (reason != null) 'authReason': reason,
        }),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  bool closed = false;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) => closed = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = FlowTokenStorage.instance;
  late Adapter api;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await storage.saveToken(token('old'));
    api = Adapter((request) =>
        request.headers[Constants.authorization] == 'Bearer new'
            ? envelope({'ok': true})
            : envelope(null, code: 401, reason: 'access_token_expired'));
    DioFactory.animeFlowDio.httpClientAdapter = api;
    DioFactory.animeFlowDio.options.headers['user-agent'] = 'AnimeFlow/test';
    DioFactory.animeFlowRefreshDio.options.headers['user-agent'] =
        'AnimeFlow/test';
  });
  tearDown(() {
    DioFactory.reset();
    FlowRefreshTokenInterceptor.onSessionExpired = null;
    FlowRefreshTokenInterceptor.onTokenRefreshed = null;
  });

  Future<AnimeFlowResponse> request() =>
      FlowClient.instance.get(AnimeFlowApi.flowUsers,
          options: Options(headers: {Constants.authorization: 'Bearer old'}));

  test(
      'factory injects an isolated signed refresh transport and merges concurrent failures',
      () async {
    var refreshed = 0;
    FlowRefreshTokenInterceptor.onTokenRefreshed = () => refreshed++;
    final started = Completer<void>();
    final result = Completer<ResponseBody>();
    final refresh = Adapter((options) {
      started.complete();
      return result.future;
    });
    DioFactory.animeFlowRefreshDio.httpClientAdapter = refresh;
    expect(
        DioFactory.animeFlowDio.interceptors
            .whereType<FlowRefreshTokenInterceptor>(),
        hasLength(1));
    expect(
        DioFactory.animeFlowRefreshDio.interceptors
            .whereType<FlowRefreshTokenInterceptor>(),
        isEmpty);
    expect(identical(DioFactory.animeFlowDio, DioFactory.animeFlowRefreshDio),
        isFalse);
    final pending = Future.wait(List.generate(10, (_) => request()));
    await started.future;
    result.complete(envelope(token('new').toJson()));
    final responses = await pending;
    expect(responses.every((response) => response.code == 200), isTrue);
    expect(api.requests.length, 20);
    expect(refresh.requests.length, 1);
    final sent = refresh.requests.single;
    expect(sent.path, AnimeFlowApi.flowRefreshToken);
    expect(sent.method, 'POST');
    expect(sent.data, {'refreshToken': 'refresh-old'});
    expect(sent.headers.containsKey(Constants.authorization), isFalse);
    final timestamp = sent.headers['X-Timestamp'] as int;
    expect(sent.headers['X-Signature'],
        ApiSignature.generateSignature(sent.path, timestamp));
    expect((await storage.getToken())?.accessToken, 'new');
    expect(refreshed, 1);
  });

  for (final status in [200, 401]) {
    for (final reason in [
      'refresh_token_invalid',
      'access_token_expired',
      'api_signature_invalid'
    ]) {
      test(
          'refresh HTTP $status with $reason does not recurse and expires only explicit revocation',
          () async {
        var expired = 0;
        FlowRefreshTokenInterceptor.onSessionExpired = () => expired++;
        final refresh = Adapter(
            (_) => envelope(null, code: 401, status: status, reason: reason));
        DioFactory.animeFlowRefreshDio.httpClientAdapter = refresh;
        await expectLater(request(), throwsA(isA<AnimeFlowApiException>()));
        expect(refresh.requests, hasLength(1));
        expect(api.requests, hasLength(1));
        final invalid = reason == 'refresh_token_invalid';
        expect(expired, invalid ? 1 : 0);
        expect(
            (await storage.getToken())?.accessToken, invalid ? isNull : 'old');
      });
    }
  }

  for (final failure in ['timeout', '429', 'invalid-json', 'invalid-token']) {
    test('refresh $failure preserves stored credentials and does not replay',
        () async {
      final refresh = Adapter((options) {
        if (failure == 'timeout') {
          throw DioException(
              requestOptions: options, type: DioExceptionType.receiveTimeout);
        }
        if (failure == '429') return envelope(null, code: 429, status: 429);
        if (failure == 'invalid-json') {
          return ResponseBody.fromString('<html>error</html>', 200, headers: {
            Headers.contentTypeHeader: ['text/html']
          });
        }
        return envelope({'accessToken': 'incomplete'});
      });
      DioFactory.animeFlowRefreshDio.httpClientAdapter = refresh;
      await expectLater(request(), throwsA(isA<AnimeFlowApiException>()));
      expect(refresh.requests, hasLength(1));
      expect(api.requests, hasLength(1));
      expect((await storage.getToken())?.refreshToken, 'refresh-old');
    });
  }

  test(
      'refresh HTTP failure without a business envelope remains a network failure',
      () async {
    DioFactory.animeFlowRefreshDio.httpClientAdapter =
        Adapter((_) => ResponseBody.fromString('', 401));
    await expectLater(
        FlowTokenRefreshClient(DioFactory.animeFlowRefreshDio)
            .refresh(refreshToken: 'refresh-old'),
        throwsA(isA<NetworkException>()
            .having((error) => error.statusCode, 'status', 401)));
    expect((await storage.getToken())?.accessToken, 'old');
  });

  for (final status in [429, 500]) {
    test('HTTP $status cannot revoke the session through a contradictory body',
        () async {
      final refresh = Adapter((_) => envelope(null,
          code: 401, status: status, reason: 'refresh_token_invalid'));
      DioFactory.animeFlowRefreshDio.httpClientAdapter = refresh;
      await expectLater(request(), throwsA(isA<AnimeFlowApiException>()));
      expect((await storage.getToken())?.accessToken, 'old');
      expect(refresh.requests, hasLength(1));
      expect(api.requests, hasLength(1));
    });
  }

  test('factory reset closes both transports and rebuilds the isolated wiring',
      () {
    final refresh = Adapter((_) => envelope(token('new').toJson()));
    final original = DioFactory.animeFlowDio;
    final originalRefresh = DioFactory.animeFlowRefreshDio;
    originalRefresh.httpClientAdapter = refresh;
    DioFactory.reset();
    expect(api.closed, isTrue);
    expect(refresh.closed, isTrue);
    expect(identical(DioFactory.animeFlowDio, original), isFalse);
    expect(identical(DioFactory.animeFlowRefreshDio, originalRefresh), isFalse);
    expect(
        DioFactory.animeFlowRefreshDio.interceptors
            .whereType<FlowRefreshTokenInterceptor>(),
        isEmpty);
  });
}

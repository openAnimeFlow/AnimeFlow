import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/core/api_signature.dart';
import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:dio/dio.dart';

typedef RefreshFlowToken = Future<FlowToken> Function(
    {required String refreshToken});

class _RefreshState {
  Future<bool>? future;
  int generation = 0;
}

/// Refresh a Flow session once per request, sharing refreshes across Dio instances.
class FlowRefreshTokenInterceptor extends Interceptor {
  FlowRefreshTokenInterceptor(
    this._dio,
    this._flowTokenRepository, {
    RefreshFlowToken? refreshToken,
  }) : _refreshToken = refreshToken ?? FlowApi.flowRefreshTokenService;

  static const skipKey = 'skipFlowTokenRefresh';
  static const _retriedKey = 'flowTokenRetried';
  static final _states = Expando<_RefreshState>();

  final Dio _dio;
  final TokenRepository<FlowToken> _flowTokenRepository;
  final RefreshFlowToken _refreshToken;

  static void Function()? onSessionExpired;
  static void Function()? onTokenRefreshed;

  /// Prevent a refresh started before logout from restoring the old session.
  static void invalidatePendingRefresh(TokenRepository<FlowToken> repository) {
    final state = _states[repository];
    if (state != null) state.generation++;
  }

  @override
  Future<void> onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) async {
    if (_shouldSkip(response.requestOptions) ||
        !_isFlowAccessFailure(response.data) ||
        !_hasAuthorization(response.requestOptions)) {
      return handler.next(response);
    }
    try {
      if (!await _refreshTokenIfNeeded(response.requestOptions)) {
        return handler.next(response);
      }
      handler.resolve(await _retryRequest(response.requestOptions));
    } catch (error, stackTrace) {
      handler.reject(_asDioError(error, stackTrace, response.requestOptions));
    }
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 ||
        !_allowsFlowRefresh(err.response?.data) ||
        _shouldSkip(err.requestOptions) ||
        !_hasAuthorization(err.requestOptions)) {
      return handler.next(err);
    }
    try {
      if (!await _refreshTokenIfNeeded(err.requestOptions)) {
        return handler.next(err);
      }
      handler.resolve(await _retryRequest(err.requestOptions));
    } catch (error, stackTrace) {
      handler.next(_asDioError(error, stackTrace, err.requestOptions));
    }
  }

  DioException _asDioError(
          Object error, StackTrace stackTrace, RequestOptions options) =>
      error is DioException
          ? error
          : DioException(
              requestOptions: options, error: error, stackTrace: stackTrace);

  bool _shouldSkip(RequestOptions options) {
    if (options.extra[skipKey] == true || options.extra[_retriedKey] == true) {
      return true;
    }
    final path = options.path;
    return path.contains('/account/refresh') ||
        path.contains('/account/email/login') ||
        path.contains('/account/oauth/bangumi/login') ||
        path.contains('/account/logout') ||
        path.contains('/account/register');
  }

  bool _hasAuthorization(RequestOptions options) =>
      options.headers[Constants.authorization]?.toString().isNotEmpty == true;

  bool _allowsFlowRefresh(dynamic data) {
    final reason = data is Map ? data['authReason'] : null;
    return reason == null || reason == 'access_token_expired';
  }

  bool _isFlowAccessFailure(dynamic data) =>
      _readBusinessCode(data) == 401 && _allowsFlowRefresh(data);

  int? _readBusinessCode(dynamic data) {
    if (data is! Map) return null;
    final code = data['code'];
    return code is int ? code : int.tryParse('$code');
  }

  Future<bool> _refreshTokenIfNeeded(RequestOptions options) {
    final state = _states[_flowTokenRepository] ??= _RefreshState();
    // Publish the shared Future before the first asynchronous storage read.
    return state.future ??=
        _refreshSession(options, state, state.generation).whenComplete(() {
      state.future = null;
    });
  }

  Future<bool> _refreshSession(
      RequestOptions options, _RefreshState state, int generation) async {
    try {
      final oldToken = await _flowTokenRepository.getToken();
      if (oldToken == null || state.generation != generation) return false;
      // A late 401 may belong to the access token replaced by another request.
      if (options.headers[Constants.authorization] !=
          '${oldToken.tokenType} ${oldToken.accessToken}') {
        return true;
      }
      if (oldToken.refreshToken.isEmpty) return false;

      FlowToken newToken;
      try {
        newToken = await _refreshToken(refreshToken: oldToken.refreshToken);
      } on AnimeFlowApiException catch (error) {
        // The backend also uses 401 for signatures and Bangumi authorization.
        // Only this refresh-endpoint error confirms that the Flow session ended.
        if (error.code == 401 &&
            (error.authReason == 'refresh_token_invalid' ||
                (error.authReason == null && error.message == '刷新令牌无效或已过期')) &&
            await _isCurrent(oldToken, state, generation)) {
          await _flowTokenRepository.removeToken();
          onSessionExpired?.call();
          return false;
        }
        rethrow;
      }
      if (!await _isCurrent(oldToken, state, generation)) return false;
      await _flowTokenRepository.saveToken(newToken);
      onTokenRefreshed?.call();
      return true;
    } catch (error) {
      // Timeouts, rate limits, storage errors and upstream failures are retryable.
      LiggLogger().w('刷新 FlowToken 未完成，保留未失效的会话 (${error.runtimeType})');
      return false;
    }
  }

  Future<bool> _isCurrent(
      FlowToken oldToken, _RefreshState state, int generation) async {
    final current = await _flowTokenRepository.getToken();
    return state.generation == generation &&
        current?.sessionId == oldToken.sessionId &&
        current?.refreshToken == oldToken.refreshToken;
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions options) async {
    final token = await _flowTokenRepository.getToken();
    if (token == null) {
      throw DioException(requestOptions: options, message: '登录会话已结束');
    }
    final data = options.data;
    return _dio.fetch(options.copyWith(
      headers: {
        ...options.headers,
        if (options.headers.containsKey('X-Signature'))
          ...ApiSignature.headers(options.path),
        Constants.authorization: '${token.tokenType} ${token.accessToken}',
      },
      extra: {...options.extra, _retriedKey: true},
      data: data is FormData ? data.clone() : data,
    ));
  }
}

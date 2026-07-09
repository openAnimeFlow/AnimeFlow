import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/network/requests/flow_request.dart';
import 'package:anime_flow/models/item/flow/flow_token.dart';
import 'package:anime_flow/repository/token_repository.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:dio/dio.dart';

/// AnimeFlow 账号 token 刷新：响应体 `code == 401` 或 HTTP 401 时自动刷新。
class FlowRefreshTokenInterceptor extends Interceptor {
  FlowRefreshTokenInterceptor(this._dio, this._flowTokenRepository);

  static const skipKey = 'skipFlowTokenRefresh';

  final Dio _dio;
  final TokenRepository<FlowToken> _flowTokenRepository;

  static void Function()? onSessionExpired;
  static void Function()? onTokenRefreshed;

  static Future<void>? _refreshFuture;

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_shouldSkip(response.requestOptions)) {
      return handler.next(response);
    }
    if (_readBusinessCode(response.data) != 401) {
      return handler.next(response);
    }
    if (!_hasAuthorization(response.requestOptions)) {
      return handler.next(response);
    }

    final refreshed = await _refreshTokenIfNeeded();
    if (!refreshed) {
      return handler.next(response);
    }

    try {
      final retryResponse = await _retryRequest(response.requestOptions);
      handler.resolve(retryResponse);
    } on DioException catch (err) {
      handler.reject(err);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }
    if (_shouldSkip(err.requestOptions)) {
      return handler.next(err);
    }
    if (!_hasAuthorization(err.requestOptions)) {
      return handler.next(err);
    }

    final refreshed = await _refreshTokenIfNeeded();
    if (!refreshed) {
      return handler.next(err);
    }

    try {
      final retryResponse = await _retryRequest(err.requestOptions);
      handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  bool _shouldSkip(RequestOptions options) {
    if (options.extra[skipKey] == true) {
      return true;
    }
    final path = options.path;
    return path.contains('/account/refresh') ||
        path.contains('/account/email/login') ||
        path.contains('/account/register');
  }

  bool _hasAuthorization(RequestOptions options) {
    final auth = options.headers[Constants.authorization];
    return auth != null && auth.toString().isNotEmpty;
  }

  int? _readBusinessCode(dynamic data) {
    if (data is! Map) {
      return null;
    }
    final code = data['code'];
    return code is int ? code : int.tryParse('$code');
  }

  Future<bool> _refreshTokenIfNeeded() async {
    while (true) {
      final inFlight = _refreshFuture;
      if (inFlight != null) {
        try {
          await inFlight;
          return true;
        } catch (_) {
          return false;
        }
      }

      final oldToken = await _flowTokenRepository.getToken();
      if (oldToken == null || oldToken.refreshToken.isEmpty) {
        await _clearSession();
        return false;
      }

      final refreshFuture = _performTokenRefresh(oldToken);
      _refreshFuture = refreshFuture;
      try {
        await refreshFuture;
        return true;
      } catch (refreshError) {
        LiggLogger().e('刷新 FlowToken 失败: $refreshError');
        await _clearSession();
        return false;
      } finally {
        if (identical(_refreshFuture, refreshFuture)) {
          _refreshFuture = null;
        }
      }
    }
  }

  Future<void> _performTokenRefresh(FlowToken oldToken) async {
    try {
      final newToken = await FlowRequest.flowRefreshTokenService(
        refreshToken: oldToken.refreshToken,
      );
      await _flowTokenRepository.saveToken(newToken);
      onTokenRefreshed?.call();
    } catch (e) {
      await _clearSession();
      rethrow;
    }
  }

  Future<void> _clearSession() async {
    await _flowTokenRepository.removeToken();
    onSessionExpired?.call();
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final token = await _flowTokenRepository.getToken();
    if (token == null) {
      throw DioException(
        requestOptions: requestOptions,
        message: 'FlowToken 不存在，无法重试请求',
      );
    }

    requestOptions.headers[Constants.authorization] =
        '${token.tokenType} ${token.accessToken}';

    final retryResponse = await _dio.fetch(requestOptions);
    if (_readBusinessCode(retryResponse.data) == 401) {
      await _clearSession();
    }
    return retryResponse;
  }
}

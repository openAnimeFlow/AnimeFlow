import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/network/requests/flow_request.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/repository/BangumiToken.dart';
import 'package:anime_flow/utils/logger.dart';
import 'package:dio/dio.dart';

class BgmRefreshTokenInterceptor extends Interceptor {
  final Dio _dio;
  final BangumiToken _bangumiToken;

  BgmRefreshTokenInterceptor(this._dio, this._bangumiToken);

  static void Function()? onSessionExpired;

  static Future<void>? _refreshFuture;

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _refreshToken(err, handler);
      return;
    }
    handler.next(err);
  }

  Future<void> _refreshToken(
    DioException e,
    ErrorInterceptorHandler handler,
  ) async {
    while (true) {
      final inFlight = _refreshFuture;
      if (inFlight != null) {
        try {
          await inFlight;
        } catch (_) {
          return handler.next(e);
        }
        return _retryAfterRefresh(e, handler);
      }
      final oldToken = await _bangumiToken.getToken();
      if (oldToken == null || oldToken.refreshToken.isEmpty) {
        await _bangumiToken.removeToken();
        return handler.next(e);
      }
      final refreshFuture = _performTokenRefresh(oldToken);
      if (_refreshFuture == null) {
        _refreshFuture = refreshFuture;
        try {
          await refreshFuture;
          return _retryAfterRefresh(e, handler);
        } catch (refreshError) {
          LiggLogger().e('刷新 token 失败: $refreshError');
          return handler.next(e);
        } finally {
          if (identical(_refreshFuture, refreshFuture)) {
            _refreshFuture = null;
          }
        }
      }
    }
  }

  Future<void> _performTokenRefresh(TokenItem oldToken) async {
    try {
      final newToken = await FlowRequest.refreshTokenService(
        refreshToken: oldToken.refreshToken,
      );
      final newTokenItem = TokenItem(
        accessToken: newToken.accessToken,
        refreshToken: newToken.refreshToken,
        expiresIn: newToken.expiresIn,
        tokenType: newToken.tokenType,
        scope: newToken.scope,
        userId: oldToken.userId,
      );
      await _bangumiToken.saveToken(newTokenItem);
    } catch (e) {
      await _bangumiToken.removeToken();
      onSessionExpired?.call();
      rethrow;
    }
  }

  Future<void> _retryAfterRefresh(
    DioException e,
    ErrorInterceptorHandler handler,
  ) async {
    final token = await _bangumiToken.getToken();
    if (token == null) {
      return handler.next(e);
    }
    final opts = e.requestOptions;
    opts.headers[Constants.authorization] =
        '${token.tokenType} ${token.accessToken}';
    try {
      final response = await _dio.fetch(opts);
      handler.resolve(response);
    } on DioException catch (err) {
      handler.next(err);
    } catch (_) {
      handler.next(e);
    }
  }
}

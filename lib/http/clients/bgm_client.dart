import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/controllers/app/app_info_controller.dart';
import 'package:anime_flow/controllers/my_controller.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/core/dio_factory.dart';
import 'package:anime_flow/http/core/network_error_mapper.dart';
import 'package:anime_flow/http/requests/anime_flow_request.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/repository/BangumiToken.dart';
import 'package:dio/dio.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:anime_flow/utils/logger.dart';

class BangumiClient {
  BangumiClient._() {
    _dio = DioFactory.bangumiDio;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await BangumiToken.instance.getToken();
          if (token != null) {
            options.headers[Constants.authorization] =
            '${token.tokenType} ${token.accessToken}';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await refreshToken(e, handler);
            return;
          }
          handler.next(e);
        },
      ),
    );
  }

  static final BangumiClient instance = BangumiClient._();

  late final Dio _dio;

  static Future<void>? _refreshFuture;

  /// GET 请求
  Future<Response<T>> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options ?? Options(headers: {Constants.userAgentName: _getBangumiUserAgent()}),
      );
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// POST 请求
  Future<Response> post(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,

      }) async {
    try {
      final Response response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options ?? Options(headers: {Constants.userAgentName: _getBangumiUserAgent()}),
      );
      return response;
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// PUT 请求
  Future<Response> put(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final Response response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options ?? Options(headers: {Constants.userAgentName: _getBangumiUserAgent()}),
      );
      return response;
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// DELETE 请求
  Future<Response> delete(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final Response response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options ?? Options(headers: {Constants.userAgentName: _getBangumiUserAgent()}),
      );
      return response;
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// HEAD 请求（用于获取资源信息，不下载内容）
  Future<Response> head(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      return await _dio.head(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options ?? Options(headers: {Constants.userAgentName: _getBangumiUserAgent()}),
      );
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// 401 时刷新 token 并重试原请求；[handler] 在本方法内且仅调用一次。
  Future<void> refreshToken(
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
      final bangumiToken = BangumiToken.instance;
      final oldToken = await bangumiToken.getToken();
      if (oldToken == null || oldToken.refreshToken.isEmpty) {
        await bangumiToken.removeToken();
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
      final newToken = await AnimeFlowRequest.refreshTokenService(
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
      await BangumiToken.instance.saveToken(newTokenItem);
    } catch (e) {
      await BangumiToken.instance.removeToken();
      final userInfoStore = Get.find<MyController>();
      userInfoStore.clearUserInfo();
      rethrow;
    }
  }

  Future<void> _retryAfterRefresh(
    DioException e,
    ErrorInterceptorHandler handler,
  ) async {
    final token = await BangumiToken.instance.getToken();
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

  static String _getBangumiUserAgent() {
    final appInfoController = Get.find<AppInfoController>();
    // todo 首次启动时 packageInfo 的版本号会还未准备好
    final version = appInfoController.appInfo.value?.version ?? '0.0.0';
    return CommonApi.bangumiUserAgent.replaceAll('{version}', version);
  }
}

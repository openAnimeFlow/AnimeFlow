import 'dart:async';

import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/controllers/app/app_info_controller.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/core/dio_factory.dart';
import 'package:anime_flow/http/core/network_error_mapper.dart';
import 'package:anime_flow/http/requests/anime_flow_request.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/stores/BangumiToken.dart';
import 'package:anime_flow/stores/user_info_store.dart';
import 'package:dio/dio.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:logger/logger.dart';

class BangumiClient {
  BangumiClient._() {
    _dio = DioFactory.bangumiDio;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await BangumiToken().getToken();
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
            refreshToken(e, handler);
          }
          return handler.next(e);
        },
      ),
    );
  }

  static final BangumiClient instance = BangumiClient._();

  late final Dio _dio;

  static bool _isRefreshing = false;
  static Completer<void>? _refreshCompleter;

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

  ///刷新token
  void refreshToken(DioException e, ErrorInterceptorHandler handler) async {
    final oldToken = await BangumiToken().getToken();

    if (oldToken != null && oldToken.refreshToken.isNotEmpty) {
      if (_isRefreshing && _refreshCompleter != null) {
        try {
          await _refreshCompleter!.future;

          final newToken = await BangumiToken().getToken();
          if (newToken != null) {
            final opts = e.requestOptions;
            opts.headers[Constants.authorization] =
                '${newToken.tokenType} ${newToken.accessToken}';
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (err) {
              return handler.next(e);
            }
          } else {
            return handler.next(e);
          }
        } catch (refreshError) {
          return handler.next(e);
        }
      } else {
        _isRefreshing = true;
        _refreshCompleter = Completer<void>();

        try {
          final newToken = await AnimeFlowRequest.refreshTokenService(
            refreshToken: oldToken.refreshToken,
          );
          TokenItem newTokenItem = TokenItem(
              accessToken: newToken.accessToken,
              refreshToken: newToken.refreshToken,
              expiresIn: newToken.expiresIn,
              tokenType: newToken.tokenType,
              scope: newToken.scope,
              userId: oldToken.userId);
          await BangumiToken().saveToken(newTokenItem);
          final opts = e.requestOptions;
          opts.headers[Constants.authorization] =
              '${newToken.tokenType} ${newToken.accessToken}';
          final response = await _dio.fetch(opts);

          _isRefreshing = false;
          _refreshCompleter?.complete();
          _refreshCompleter = null;
          return handler.resolve(response);
        } catch (refreshError) {
          final UserInfoStore userInfoStore = UserInfoStore();
          _isRefreshing = false;
          _refreshCompleter?.completeError(refreshError);
          _refreshCompleter = null;
          await BangumiToken().deleteToken();
          userInfoStore.clearUserInfo();
          Logger().e('刷新 token 失败: $refreshError');
          return handler.next(e);
        }
      }
    } else {
      await BangumiToken().deleteToken();
      return handler.next(e);
    }
  }

  static String _getBangumiUserAgent() {
    final appInfoController = Get.find<AppInfoController>();
    return CommonApi.bangumiUserAgent
        .replaceAll('{version}', appInfoController.version);
  }
}

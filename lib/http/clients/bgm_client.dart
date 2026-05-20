import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/controllers/app/app_info_controller.dart';
import 'package:anime_flow/http/api_path.dart';
import 'package:anime_flow/http/core/dio_factory.dart';
import 'package:anime_flow/http/core/network_error_mapper.dart';
import 'package:anime_flow/http/interceptors/bgm_authInterceptor.dart';
import 'package:anime_flow/http/interceptors/bgm_refresh_tokenInterceptor.dart';
import 'package:anime_flow/repository/BangumiToken.dart';
import 'package:dio/dio.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

class BangumiClient {
  BangumiClient._() {
    _dio = DioFactory.bangumiDio;
    final tokenRepo = BangumiToken.instance;
    _dio.interceptors.add(BgmAuthInterceptor(tokenRepo));
    _dio.interceptors.add(BgmRefreshTokeninterceptor(_dio, tokenRepo));
  }

  static final BangumiClient instance = BangumiClient._();

  late final Dio _dio;

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

  static String _getBangumiUserAgent() {
    final appInfoController = Get.find<AppInfoController>();
    final version = appInfoController.appInfo.value?.version ?? '0.0.0';
    return CommonApi.bangumiUserAgent.replaceAll('{version}', version);
  }
}

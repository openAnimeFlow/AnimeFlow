import 'package:anime_flow/http/core/dio_factory.dart';
import 'package:anime_flow/http/core/network_error_mapper.dart';
import 'package:dio/dio.dart';

class AnimeFlowClient {
  AnimeFlowClient._();

  static final AnimeFlowClient instance = AnimeFlowClient._();

  /// GET 请求
  Future<dynamic> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await DioFactory.animeFlowDio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// POST 请求
  Future<dynamic> post(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await DioFactory.animeFlowDio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// PUT 请求
  Future<dynamic> put(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await DioFactory.animeFlowDio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options ,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// DELETE 请求
  Future<dynamic> delete(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      final response = await DioFactory.animeFlowDio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// HEAD 请求（用于获取资源信息，不下载内容）
  Future<dynamic> head(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      return await DioFactory.animeFlowDio.head(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }
}
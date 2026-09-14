import 'package:anime_flow/core/network/core/api_signature.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/network/core/network_error_mapper.dart';
import 'package:dio/dio.dart';

class LiggClient {
  LiggClient._();

  static final LiggClient instance = LiggClient._();

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await DioFactory.liggDio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _signedOptions(path, options),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await DioFactory.liggDio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _signedOptions(path, options),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await DioFactory.liggDio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _signedOptions(path, options),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await DioFactory.liggDio.delete<T>(
        path,
        queryParameters: queryParameters,
        options: _signedOptions(path, options),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  Options _signedOptions(String path, Options? options) {
    return (options ?? Options()).copyWith(
      headers: {
        ...?options?.headers,
        ...ApiSignature.headers(path),
      },
    );
  }
}

import 'package:anime_flow/http/core/dio_factory.dart';
import 'package:anime_flow/http/core/network_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:anime_flow/utils/logger.dart';

class GithubClient {
  GithubClient._();

  static final GithubClient instance = GithubClient._();


  /// GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await DioFactory.githubDio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
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
  }) async {
    try {
      final Response response = await DioFactory.githubDio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
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
  }) async {
    try {
      final Response response = await DioFactory.githubDio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// 下载文件
  Future<Response> download(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response response = await DioFactory.apiDio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        LiggLogger().i('下载已取消');
        throw '下载已取消';
      }
      throw await NetworkErrorMapper.mapException(e);
    }
  }
}

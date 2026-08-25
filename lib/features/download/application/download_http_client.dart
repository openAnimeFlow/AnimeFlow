import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:dio/dio.dart';

class DownloadHttpClient {
  DownloadHttpClient({Dio? dio}) : _dio = dio ?? DioFactory.downloadDio;

  final Dio _dio;

  Future<String> getPlain(
    String url, {
    required Map<String, String> headers,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await _dio.get<String>(
      url,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      options: Options(
        headers: headers,
        responseType: ResponseType.plain,
      ),
    );
    return response.data ?? '';
  }

  Future<Response<ResponseBody>> getStream(
    String url, {
    required Map<String, String> headers,
    CancelToken? cancelToken,
  }) {
    return _dio.get<ResponseBody>(
      url,
      cancelToken: cancelToken,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
      ),
    );
  }

  Future<void> download(
    String url,
    String savePath, {
    required Map<String, String> headers,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    await _dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      options: Options(headers: headers),
    );
  }
}

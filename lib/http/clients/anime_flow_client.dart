import 'package:anime_flow/http/core/dio_factory.dart';
import 'package:anime_flow/http/core/network_error_mapper.dart';
import 'package:dio/dio.dart';

/// AnimeFlow API 统一响应：`{ code, message, data }`。
class AnimeFlowResponse {
  const AnimeFlowResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  final int code;
  final String message;
  final Map<String, dynamic> data;

  factory AnimeFlowResponse.fromJson(Map<String, dynamic> json) {
    final dataRaw = json['data'];
    return AnimeFlowResponse(
      code: json['code'] as int,
      message: json['message'] as String? ?? '',
      data: dataRaw is Map
          ? Map<String, dynamic>.from(dataRaw)
          : <String, dynamic>{},
    );
  }
}

class AnimeFlowClient {
  AnimeFlowClient._();

  static final AnimeFlowClient instance = AnimeFlowClient._();

  static AnimeFlowResponse _parseEnvelope(dynamic raw) {
    if (raw is Map) {
      return AnimeFlowResponse.fromJson(Map<String, dynamic>.from(raw));
    }
    throw FormatException('AnimeFlow API response must be a JSON object: $raw');
  }

  /// GET 请求
  Future<AnimeFlowResponse> get(
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
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// POST 请求
  Future<AnimeFlowResponse> post(
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
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// PUT 请求
  Future<AnimeFlowResponse> put(
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
        options: options,
        cancelToken: cancelToken,
      );
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// DELETE 请求
  Future<AnimeFlowResponse> delete(
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
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }

  /// HEAD 请求（用于获取资源信息，不下载内容）
  Future<Response<dynamic>> head(
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

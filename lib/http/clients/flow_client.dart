import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/core/api_signature.dart';
import 'package:anime_flow/http/core/network_exception.dart';
import 'package:anime_flow/http/core/dio_factory.dart';
import 'package:anime_flow/http/core/network_error_mapper.dart';
import 'package:anime_flow/http/interceptors/flow_refresh_token_interceptor.dart';
import 'package:anime_flow/repository/flow_token_storage.dart';
import 'package:dio/dio.dart';

/// AnimeFlow API 业务异常：`code != 200` 时抛出。
class AnimeFlowApiException implements Exception {
  const AnimeFlowApiException({
    required this.code,
    required this.message,
  });

  final int code;
  final String message;

  @override
  String toString() => message;
}

/// 将 Flow 业务异常、网络异常等转换为用户可读提示。
String resolveAnimeFlowErrorMessage(
  Object error, {
  required String fallback,
}) {
  if (error is AnimeFlowApiException) {
    final message = error.message.trim();
    return message.isNotEmpty ? message : fallback;
  }
  if (error is NetworkException) {
    final message = error.message.trim();
    return message.isNotEmpty ? message : fallback;
  }
  if (error is StateError) {
    return error.message;
  }
  return fallback;
}

/// AnimeFlow API 统一响应：`{ code, message, data }`。
class AnimeFlowResponse {
  const AnimeFlowResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  final int code;
  final String message;
  final dynamic data;

  factory AnimeFlowResponse.fromJson(Map<String, dynamic> json) {
    return AnimeFlowResponse(
      code: json['code'] as int,
      message: json['message'] as String? ?? '',
      data: json['data'],
    );
  }
}

class FlowClient {
  FlowClient._();

  static final FlowClient instance = FlowClient._();

  static AnimeFlowResponse _parseEnvelope(dynamic raw) {
    if (raw is Map) {
      final response =
          AnimeFlowResponse.fromJson(Map<String, dynamic>.from(raw));
      if (response.code != 200) {
        throw AnimeFlowApiException(
          code: response.code,
          message: response.message,
        );
      }

      return response;
    }
    throw FormatException('AnimeFlow API response must be a JSON object: $raw');
  }

  Future<Options> _resolveOptions({
    required String path,
    Options? options,
    required bool signRequest,
    bool skipFlowTokenRefresh = false,
    bool includeFlowToken = true,
  }) async {
    if (!signRequest && !skipFlowTokenRefresh && !includeFlowToken) {
      return options ?? Options();
    }

    final signHeaders =
        signRequest ? ApiSignature.headers(path) : <String, dynamic>{};
    final mergedHeaders = <String, dynamic>{
      ...?options?.headers,
      ...signHeaders,
    };
    if (includeFlowToken) {
      final token = await FlowTokenStorage.instance.getToken();
      if (token != null) {
        mergedHeaders[Constants.authorization] = '${token.tokenType} ${token.accessToken}';
      }
    }
    final mergedExtra = <String, dynamic>{
      ...?options?.extra,
      if (skipFlowTokenRefresh) FlowRefreshTokenInterceptor.skipKey: true,
    };
    return (options ?? Options()).copyWith(
      headers: mergedHeaders,
      extra: mergedExtra,
    );
  }

  /// GET 请求
  Future<AnimeFlowResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool signRequest = true,
    bool skipFlowTokenRefresh = false,
    bool includeFlowToken = true,
  }) async {
    try {
      final response = await DioFactory.animeFlowDio.get(
        path,
        queryParameters: queryParameters,
        options: await _resolveOptions(
          path: path,
          options: options,
          signRequest: signRequest,
          skipFlowTokenRefresh: skipFlowTokenRefresh,
          includeFlowToken: includeFlowToken,
        ),
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
    bool signRequest = true,
    bool skipFlowTokenRefresh = false,
    bool includeFlowToken = true,
  }) async {
    try {
      final response = await DioFactory.animeFlowDio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: await _resolveOptions(
          path: path,
          options: options,
          signRequest: signRequest,
          skipFlowTokenRefresh: skipFlowTokenRefresh,
          includeFlowToken: includeFlowToken,
        ),
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
    bool signRequest = true,
    bool skipFlowTokenRefresh = false,
    bool includeFlowToken = true,
  }) async {
    try {
      final response = await DioFactory.animeFlowDio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: await _resolveOptions(
          path: path,
          options: options,
          signRequest: signRequest,
          skipFlowTokenRefresh: skipFlowTokenRefresh,
          includeFlowToken: includeFlowToken,
        ),
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
    bool signRequest = true,
    bool skipFlowTokenRefresh = false,
    bool includeFlowToken = true,
  }) async {
    try {
      final response = await DioFactory.animeFlowDio.delete(
        path,
        queryParameters: queryParameters,
        options: await _resolveOptions(
          path: path,
          options: options,
          signRequest: signRequest,
          skipFlowTokenRefresh: skipFlowTokenRefresh,
          includeFlowToken: includeFlowToken,
        ),
        cancelToken: cancelToken,
      );
      return _parseEnvelope(response.data);
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }
}

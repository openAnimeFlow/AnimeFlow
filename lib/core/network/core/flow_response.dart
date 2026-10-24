import 'network_exception.dart';

/// AnimeFlow API 业务异常：`code != 200` 时抛出。
class AnimeFlowApiException implements Exception {
  const AnimeFlowApiException({
    required this.code,
    required this.message,
    this.authReason,
  });

  final int code;
  final String message;
  final String? authReason;

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
      data: json['data'] as dynamic,
    );
  }
}

AnimeFlowResponse parseAnimeFlowResponse(dynamic raw, {int? statusCode}) {
  if (statusCode == 204 || raw == null) {
    return const AnimeFlowResponse(code: 200, message: '', data: null);
  }
  if (raw is Map) {
    final response = AnimeFlowResponse.fromJson(Map<String, dynamic>.from(raw));
    if (response.code != 200) {
      throw AnimeFlowApiException(
        code: response.code,
        message: response.message,
        authReason: raw['authReason'] as String?,
      );
    }

    return response;
  }
  throw FormatException('AnimeFlow API response must be a JSON object: $raw');
}

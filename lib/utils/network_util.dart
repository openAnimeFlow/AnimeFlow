import 'package:dio/dio.dart';

class NetworkCheckResult {
  const NetworkCheckResult({
    required this.reachable,
    required this.latencyMs,
    this.statusCode,
    this.message,
  });

  final bool reachable;
  final int latencyMs;
  final int? statusCode;
  final String? message;
}

class NetworkUtil {
  NetworkUtil._();

  static Future<NetworkCheckResult> checkReachability({
    required String url,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final normalizedUrl = url.trim();
    final validationError = _validateUrl(normalizedUrl);
    if (validationError != null) {
      return NetworkCheckResult(
        reachable: false,
        latencyMs: 0,
        message: validationError,
      );
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: timeout,
        receiveTimeout: timeout,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    final stopwatch = Stopwatch()..start();
    try {
      final response = await dio.get(
        normalizedUrl,
        options: Options(
          followRedirects: true,
          receiveDataWhenStatusError: true,
        ),
      );
      stopwatch.stop();
      final statusCode = response.statusCode;
      final reachable = statusCode != null && statusCode < 400;
      return NetworkCheckResult(
        reachable: reachable,
        latencyMs: stopwatch.elapsedMilliseconds,
        statusCode: statusCode,
        message: reachable ? null : '服务器返回异常状态（$statusCode）',
      );
    } on DioException catch (e) {
      stopwatch.stop();
      return NetworkCheckResult(
        reachable: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        message: _mapDioError(e, normalizedUrl),
      );
    } finally {
      dio.close();
    }
  }

  static String? _validateUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'URL 格式无效';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return '仅支持 http/https 协议';
    }
    return null;
  }

  static String _mapDioError(DioException e, String url) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout => '连接超时，请检查网络或代理设置',
      DioExceptionType.receiveTimeout => '响应超时，请稍后重试',
      DioExceptionType.connectionError => '无法连接 $url',
      DioExceptionType.badCertificate => '证书校验失败',
      _ => '网络请求失败',
    };
  }
}

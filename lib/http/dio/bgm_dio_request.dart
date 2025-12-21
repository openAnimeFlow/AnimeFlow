import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/stores/TokenStorage.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class BgmDioRequest {
  final logger = Logger();

  static Dio? _dio;
  static final BgmDioRequest _instance = BgmDioRequest._internal();

  factory BgmDioRequest() => _instance;

  BgmDioRequest._internal() {
    _dio = Dio();
    // 配置dio实例
    _dio!.options.connectTimeout = const Duration(seconds: 10); // 连接超时时间
    _dio!.options.receiveTimeout = const Duration(seconds: 10); // 超时时间

    // 添加拦截器
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.getToken();
          if (token != null) {
            options.headers[Constants.authorization] =
                '${token.tokenType} ${token.accessToken}';
          }
          logger.i(
            'HTTP Request: ${options.method} ${options.path}',
            time: DateTime.now(),
            stackTrace: StackTrace.current,
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          logger.i(
            'HTTP Response: ${response.statusCode} ${response.data}',
            time: DateTime.now(),
            stackTrace: StackTrace.current,
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // await tokenStorage.deleteToken();
            // clearAuthorization();
          }
          logger.e('error: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  /// GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio!.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
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
      final Response response = await _dio!.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
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
      final Response response = await _dio!.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE 请求
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final Response response = await _dio!.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// HEAD 请求（用于获取资源信息，不下载内容）
  Future<Response> head(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio!.head(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 下载文件
  Future<Response> download(String url, String savePath) async {
    try {
      final Response response = await _dio!.download(url, savePath);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 上传文件
  Future<Response> upload(String path, FormData formData) async {
    try {
      final Response response = await _dio!.post(path, data: formData);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 统一错误处理
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '请求超时';
      case DioExceptionType.receiveTimeout:
        return '响应超时';
      case DioExceptionType.badResponse:
        if (error.response != null) {
          return '服务器错误: ${error.response!.statusMessage}';
        }
        return '服务器错误';
      case DioExceptionType.cancel:
        return '请求取消';
      case DioExceptionType.unknown:
        return '未知错误';
      default:
        return '网络错误';
    }
  }

  /// 设置认证token
  void setAuthorization(TokenItem token) async {
     _dio!.options.headers[Constants.authorization] =
        '${token.tokenType} ${token.accessToken}';
  }

  /// 清除认证信息
  void clearAuthorization() {
    _dio!.options.headers.remove(Constants.authorization);
  }
}

final bgmDioRequest = BgmDioRequest();

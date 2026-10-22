import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/network/core/api_signature.dart';
import 'package:anime_flow/core/network/core/flow_response.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/core/network/core/network_error_mapper.dart';
import 'package:anime_flow/core/network/interceptors/flow_refresh_token_interceptor.dart';
import 'package:anime_flow/core/auth/repository/flow_token_storage.dart';
import 'package:dio/dio.dart';

export 'package:anime_flow/core/network/core/flow_response.dart';

class FlowClient {
  FlowClient._();

  static final FlowClient instance = FlowClient._();

  Future<Options> _resolveOptions({
    required String path,
    Options? options,
    required bool signRequest,
    bool skipFlowTokenRefresh = false,
    bool includeFlowToken = true,
    bool requireFlowToken = false,
  }) async {
    if (!signRequest &&
        !skipFlowTokenRefresh &&
        !includeFlowToken &&
        !requireFlowToken) {
      return options ?? Options();
    }

    final signHeaders =
        signRequest ? ApiSignature.headers(path) : <String, dynamic>{};
    final mergedHeaders = <String, dynamic>{
      ...?options?.headers,
      ...signHeaders,
    };
    if (includeFlowToken &&
        !mergedHeaders.containsKey(Constants.authorization)) {
      final token = await FlowTokenStorage.instance.getToken();
      if (token != null) {
        mergedHeaders[Constants.authorization] =
            '${token.tokenType} ${token.accessToken}';
      } else if (requireFlowToken) {
        throw StateError('未登录');
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

  /// SSE handshake. Events bypass the normal JSON envelope parser.
  Future<ResponseBody> openEventStream(
    String path,
    CancelToken cancelToken, {
    bool requireFlowToken = true,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await DioFactory.animeFlowDio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: await _resolveOptions(
        path: path,
        signRequest: true,
        requireFlowToken: requireFlowToken,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Accept': 'text/event-stream, application/json'},
        ),
      ),
      cancelToken: cancelToken,
    );
    if (response.data is Map) parseAnimeFlowResponse(response.data);
    if (response.data is! ResponseBody ||
        response.headers.value('content-type')?.contains('text/event-stream') !=
            true) {
      throw const FormatException('Expected a collection status event stream');
    }
    return response.data as ResponseBody;
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
    bool requireFlowToken = false,
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
          requireFlowToken: requireFlowToken,
        ),
        cancelToken: cancelToken,
      );
      return parseAnimeFlowResponse(response.data,
          statusCode: response.statusCode);
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
    bool requireFlowToken = false,
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
          requireFlowToken: requireFlowToken,
        ),
        cancelToken: cancelToken,
      );
      return parseAnimeFlowResponse(response.data,
          statusCode: response.statusCode);
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
    bool requireFlowToken = false,
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
          requireFlowToken: requireFlowToken,
        ),
        cancelToken: cancelToken,
      );
      return parseAnimeFlowResponse(response.data,
          statusCode: response.statusCode);
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
    bool requireFlowToken = false,
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
          requireFlowToken: requireFlowToken,
        ),
        cancelToken: cancelToken,
      );
      return parseAnimeFlowResponse(response.data,
          statusCode: response.statusCode);
    } on DioException catch (e) {
      throw await NetworkErrorMapper.mapException(e);
    }
  }
}

import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/core/api_signature.dart';
import 'package:anime_flow/core/network/core/flow_response.dart';
import 'package:anime_flow/core/network/core/network_error_mapper.dart';
import 'package:dio/dio.dart';

/// Refreshes credentials using a transport supplied by the network factory.
/// This client never reads credentials or retries authentication failures.
class FlowTokenRefreshClient {
  const FlowTokenRefreshClient(this._dio);
  final Dio _dio;

  Future<FlowToken> refresh({required String refreshToken}) async {
    const path = AnimeFlowApi.flowRefreshToken;
    try {
      final response = await _dio.post<dynamic>(path,
          data: {'refreshToken': refreshToken},
          options: Options(headers: ApiSignature.headers(path)));
      final envelope = parseAnimeFlowResponse(response.data,
          statusCode: response.statusCode);
      return FlowToken.fromJson(envelope.data as Map<String, dynamic>);
    } on DioException catch (error) {
      // HTTP 401 may carry the same explicit revocation reason as HTTP 200.
      // Preserve that business error so the owner can expire the session.
      if (error.type == DioExceptionType.badResponse &&
          error.response?.statusCode == 401 &&
          error.response?.data is Map) {
        parseAnimeFlowResponse(error.response!.data,
            statusCode: error.response!.statusCode);
      }
      throw await NetworkErrorMapper.mapException(error);
    }
  }
}

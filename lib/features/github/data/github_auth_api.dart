import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/features/github/domain/github_auth_models.dart';
import 'package:dio/dio.dart';

abstract class GitHubAuthApi {
  Future<GitHubDeviceSession> requestDeviceCode();
  Future<GitHubExchangeResult> exchangeDeviceCode(String deviceCode);
  Future<GitHubUser> getCurrentUser(String accessToken);
  Future<GitHubToken> refreshToken(String refreshToken);
}

class GitHubRefreshInvalidException implements Exception {
  const GitHubRefreshInvalidException();
}

class GitHubAuthApiImpl implements GitHubAuthApi {
  GitHubAuthApiImpl({Dio? oauthDio, String? clientId})
      : _oauthDio = oauthDio,
        _clientId = clientId ?? configuredClientId;

  static const configuredClientId =
      String.fromEnvironment('GITHUB_APP_CLIENT_ID');
  final Dio? _oauthDio;
  final String _clientId;

  @override
  Future<GitHubDeviceSession> requestDeviceCode() async {
    if (_clientId.isEmpty) {
      throw StateError('客户端未配置 GITHUB_APP_CLIENT_ID');
    }
    final response =
        await (_oauthDio ?? DioFactory.githubOAuthDio).post<dynamic>(
      GitHubApi.deviceCode,
      data: {'client_id': _clientId},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Accept': 'application/json'},
      ),
    );
    return GitHubDeviceSession.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      DateTime.now(),
    );
  }

  @override
  Future<GitHubExchangeResult> exchangeDeviceCode(String deviceCode) async {
    final response = await FlowClient.instance.post(
      AnimeFlowApi.githubDeviceExchange,
      data: {'deviceCode': deviceCode},
      includeFlowToken: false,
      skipFlowTokenRefresh: true,
    );
    return GitHubExchangeResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
      DateTime.now(),
    );
  }

  @override
  Future<GitHubUser> getCurrentUser(String accessToken) async {
    final response = await DioFactory.githubAuthorizedDio.get<dynamic>(
      GitHubApi.currentUser,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return GitHubUser.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<GitHubToken> refreshToken(String refreshToken) async {
    if (_clientId.isEmpty) {
      throw StateError('客户端未配置 GITHUB_APP_CLIENT_ID');
    }
    late final Response<dynamic> response;
    try {
      response = await (_oauthDio ?? DioFactory.githubOAuthDio).post<dynamic>(
        GitHubApi.accessToken,
        data: {
          'client_id': _clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Accept': 'application/json'},
        ),
      );
    } on DioException catch (error) {
      final body = error.response?.data;
      if (body is Map && body['error'] == 'bad_refresh_token') {
        throw const GitHubRefreshInvalidException();
      }
      rethrow;
    }
    final payload = Map<String, dynamic>.from(response.data as Map);
    final error = payload['error'];
    if (error == 'bad_refresh_token') {
      throw const GitHubRefreshInvalidException();
    }
    if (error is String && error.isNotEmpty) {
      throw StateError('GitHub 拒绝刷新授权：$error');
    }
    return GitHubToken.fromRefresh(payload, DateTime.now());
  }
}

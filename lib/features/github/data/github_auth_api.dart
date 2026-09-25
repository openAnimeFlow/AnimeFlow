import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/features/github/domain/github_auth_models.dart';
import 'package:dio/dio.dart';

abstract class GitHubAuthApi {
  Future<GitHubDeviceSession> requestDeviceCode();
  Future<GitHubExchangeResult> exchangeDeviceCode(String deviceCode);
  Future<GitHubUser> getCurrentUser(String accessToken);
}

class GitHubAuthApiImpl implements GitHubAuthApi {
  const GitHubAuthApiImpl();

  static const clientId = String.fromEnvironment('GITHUB_APP_CLIENT_ID');

  @override
  Future<GitHubDeviceSession> requestDeviceCode() async {
    if (clientId.isEmpty) {
      throw StateError('客户端未配置 GITHUB_APP_CLIENT_ID');
    }
    final response = await DioFactory.githubOAuthDio.post<dynamic>(
      GitHubApi.deviceCode,
      data: {'client_id': clientId},
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
}

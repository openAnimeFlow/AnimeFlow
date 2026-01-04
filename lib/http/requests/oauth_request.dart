import 'package:anime_flow/http/api/anime_flow_api.dart';
import 'package:anime_flow/http/dio/bgm_dio_request.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:anime_flow/utils/utils.dart';

class OAuthRequest {
  static const String _animeFlowApi = AnimeFlowApi.animeFlowApi;

  static Future<TokenItem> getTokenService({required String code}) async {
    final response = await bgmDioRequest.post(
        _animeFlowApi + AnimeFlowApi.token,
        queryParameters: {'code': code});
    return TokenItem.fromJson(response.data['data']);
  }

  ///刷新token
  static Future<TokenItem> refreshTokenService({required String refreshToken}) async {
    final response = await dioRequest.post(
        '$_animeFlowApi${AnimeFlowApi.refreshToken}',
        queryParameters: {'refreshToken': refreshToken});
    return TokenItem.fromJson(response.data['data']);
  }

  //回调api
  static Future<Map<String, dynamic>> callbackService(
      String code, String state) async {
    return await dioRequest.get(_animeFlowApi + AnimeFlowApi.callback,
        queryParameters: {
          'code': code,
          'state': state
        }).then((value) => value.data);
  }

  //获取session
  static Future<Map<String, dynamic>> getSessionService() async {
    String deviceName = Utils.getDevice().toUpperCase();
    return await dioRequest.get(_animeFlowApi + AnimeFlowApi.session,
        queryParameters: {'platform': deviceName}).then((value) => value.data);
  }

  // 持续轮询直到获取到 token 或超时（60秒，与 session 过期时间一致）
  static Future<TokenItem?> pollTokenService({required String state}) async {
    const maxDuration = Duration(seconds: 60); // session 过期时间
    const pollInterval = Duration(seconds: 2); // 每2秒轮询一次
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxDuration) {
      try {
        final response = await dioRequest.get(
          _animeFlowApi + AnimeFlowApi.token,
          queryParameters: {'sessionId': state},
        );

        if (response.data['code'] == 200 && response.data['data'] != null) {
          return TokenItem.fromJson(response.data['data']);
        }
      } catch (e) {
        // 忽略错误，继续轮询
      }

      await Future.delayed(pollInterval);
    }

    return null; // 超时未获取到 token
  }
}

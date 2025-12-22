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
}

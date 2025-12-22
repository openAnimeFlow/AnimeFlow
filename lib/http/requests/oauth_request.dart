import 'package:anime_flow/http/api/anime_flow_api.dart';
import 'package:anime_flow/http/dio/bgm_dio_request.dart';
import 'package:anime_flow/http/dio/dio_request.dart';
import 'package:anime_flow/models/item/token_item.dart';

class OAuthRequest {
  static const String _animeFlowApi = AnimeFlowApi.animeFlowApi;

  static Future<TokenItem> getTokenService({required String code}) async {
    final response = await bgmDioRequest.post(
        _animeFlowApi + AnimeFlowApi.token,
        queryParameters: {'code': code});
    return TokenItem.fromJson(response.data['data']);
  }

  //获取session
  static Future<Map<String, dynamic>> getSessionService() async {
    return await dioRequest
        .get(_animeFlowApi + AnimeFlowApi.session)
        .then((value) => value.data);
  }
}

import 'package:anime_flow/http/api/anime_flow_api.dart';
import 'package:anime_flow/http/dio/bgm_dio_request.dart';
import 'package:anime_flow/models/item/token_item.dart';
import 'package:logger/logger.dart';

class OAuthRequest {
  static const String _animeFlowApi = AnimeFlowApi.ainmeFlowApi;

  static Future<TokenItem> getTokenService({required String code}) async {
    final response = await bgmDioRequest.post(
        _animeFlowApi + AnimeFlowApi.token,
        queryParameters: {'code': code});
    return TokenItem.fromJson(response.data['data']);
  }
}

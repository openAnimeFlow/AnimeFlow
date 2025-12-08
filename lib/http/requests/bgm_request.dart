import 'package:anime_flow/constants/constants.dart';
import 'package:anime_flow/http/api/bgm_api.dart';
import 'package:anime_flow/http/api/common_api.dart';
import 'package:anime_flow/models/item/episodes_item.dart';
import 'package:anime_flow/models/item/hot_item.dart';
import 'package:anime_flow/models/item/subjects_item.dart';
import 'package:anime_flow/utils/http/dio_request.dart';
import 'package:dio/dio.dart';

class BgmRequest {
  /// 获取热门
  static Future<HotItem> getHotService(int limit, int offset) async {
    final response = await dioRequest.get(BgmApi.hot,
        queryParameters: {"type": 2, "limit": limit, "offset": offset},
        options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent}));
    return HotItem.fromJson(response.data);
  }

  ///根据id获取条目
  static Future<SubjectsItem> getSubjectByIdService(int id) async {
    final response = await dioRequest.get(
        BgmApi.subjectById.replaceFirst('{subjectId}', id.toString()),
        options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent}));
    return SubjectsItem.fromJson(response.data);
  }

  ///获取条目章节
  static Future<EpisodesItem> getSubjectEpisodesByIdService(
      int id, int limit, int offset) async {
    final response = await dioRequest.get(
        BgmApi.episodes.replaceFirst('{subjectId}', id.toString()),
        queryParameters: {"limit": limit, "offset": offset},
        options: Options(
            headers: {Constants.userAgentName: CommonApi.bangumiUserAgent}));
    return EpisodesItem.fromJson(response.data);
  }
}

import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anime_info_provider.g.dart';

@riverpod
class AnimeInfo extends _$AnimeInfo {
  @override
  Future<SubjectsInfoItem?> build(int subjectId) async {
    return BgmRequest.getSubjectByIdService(subjectId);
  }

  void setAnimeInfo(SubjectsInfoItem? animeInfo) {
    state = AsyncData(animeInfo);
  }
}

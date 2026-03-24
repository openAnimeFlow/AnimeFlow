import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final animeInfoProvider = AutoDisposeAsyncNotifierProviderFamily<
    AnimeInfoNotifier, SubjectsInfoItem?, int>(AnimeInfoNotifier.new);

class AnimeInfoNotifier
    extends AutoDisposeFamilyAsyncNotifier<SubjectsInfoItem?, int> {
  @override
  Future<SubjectsInfoItem?> build(int subjectId) async {
    return BgmRequest.getSubjectByIdService(subjectId);
  }

  void setAnimeInfo(SubjectsInfoItem? animeInfo) {
    state = AsyncData(animeInfo);
  }
}

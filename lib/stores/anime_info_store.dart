import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final animeInfoProvider = AsyncNotifierProvider.autoDispose
    .family<AnimeInfoNotifier, SubjectsInfoItem?, int>(AnimeInfoNotifier.new);

class AnimeInfoNotifier extends AsyncNotifier<SubjectsInfoItem?> {
  AnimeInfoNotifier(this.subjectId);

  final int subjectId;

  @override
  Future<SubjectsInfoItem?> build() async {
    return BgmRequest.getSubjectByIdService(subjectId);
  }

  void setAnimeInfo(SubjectsInfoItem? animeInfo) {
    state = AsyncData(animeInfo);
  }
}

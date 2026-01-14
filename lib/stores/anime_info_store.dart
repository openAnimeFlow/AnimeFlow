import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:get/get.dart';

class AnimeInfoStore extends GetxController {
  final Rx<SubjectsInfoItem?> animeInfo = Rx<SubjectsInfoItem?>(null);

  void setAnimeInfo(SubjectsInfoItem? animeInfo) {
    this.animeInfo.value = animeInfo;
  }
}
import 'package:get/get.dart';

class EpisodesController extends GetxController {
  final RxString episodeTitle = ''.obs;
  final RxInt episodeSort = 0.obs;
  final RxInt episodeIndex = 0.obs;
  final RxInt episodeId = 0.obs;

  void setEpisodeTitle(String title) {
    episodeTitle.value = title;
  }

  void setEpisodeSort({required int sort, required int episodeIndex, required int episodeId}) {
    episodeSort.value = sort;
    this.episodeIndex.value = episodeIndex;
    this.episodeId.value = episodeId;
  }
}

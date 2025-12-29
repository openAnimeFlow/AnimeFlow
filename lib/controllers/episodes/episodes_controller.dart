import 'package:get/get.dart';

class EpisodesController extends GetxController {
  final RxString episodeTitle = ''.obs;
  final RxDouble episodeSort = 0.0.obs;
  final RxInt episodeIndex = 0.obs;
  final RxInt episodeId = 0.obs;

  void setEpisodeTitle(String title) {
    episodeTitle.value = title;
  }

  void setEpisodeSort({required num sort, required int episodeIndex, required int episodeId}) {
    // 只有当值真的变化时才更新，避免不必要的通知触发
    if (episodeSort.value != sort) {
      episodeSort.value = sort.toDouble();
    }
    if (this.episodeIndex.value != episodeIndex) {
      this.episodeIndex.value = episodeIndex;
    }
    if (this.episodeId.value != episodeId) {
      this.episodeId.value = episodeId;
    }
  }
}

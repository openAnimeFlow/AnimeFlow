import 'package:anime_flow/models/item/bangumi/episodes_item.dart';
import 'package:get/get.dart';
import 'package:anime_flow/utils/logger.dart';

class EpisodesState extends GetxController {
  final Rx<EpisodesItem?> episodes = Rx<EpisodesItem?>(null);
  final RxString episodeTitle = ''.obs;
  final RxDouble episodeSort = 0.0.obs;
  final RxInt episodeIndex = 0.obs;
  final RxInt episodeId = 0.obs;
  final RxBool isLoading = false.obs;

  void setEpisodeTitle(String title) {
    episodeTitle.value = title;
  }

  void setEpisodeSort({required num sort, required int episodeIndex, required int episodeId}) {
    if (episodeSort.value != sort) {
      episodeSort.value = sort.toDouble();
    }
    if (this.episodeIndex.value != episodeIndex) {
      LiggLogger().i('选中剧集索引:$episodeIndex');
      this.episodeIndex.value = episodeIndex;
    }
    if (this.episodeId.value != episodeId) {
      this.episodeId.value = episodeId;
    }
  }
}

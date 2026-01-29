import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:get/get.dart';

class PlaySubjectState extends GetxController {
  late Rx<SubjectBasicData> subject;

  ///继续观看的剧集号
  final RxInt continueEpisode = 0.obs;

  PlaySubjectState(SubjectBasicData subject) {
    this.subject = subject.obs;
  }

  void setContinueEpisode(int episode) {
    continueEpisode.value = episode;
  }
}

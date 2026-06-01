import 'package:anime_flow/routes/model/play_route_extra.dart';
import 'package:get/get.dart';

class PlaySubjectState extends GetxController {
  late Rx<PlayExtra> subject;

  ///继续观看的剧集号
  final RxInt continueEpisode = 0.obs;

  PlaySubjectState(PlayExtra subject) {
    this.subject = subject.obs;
  }

  void setContinueEpisode(int episode) {
    continueEpisode.value = episode;
  }
}

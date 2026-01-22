import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlaybackEngine extends GetxController {
  late final Player player;
  late final VideoController videoController;

  PlaybackEngine() {
    player = Player();
    videoController = VideoController(player);
  }

  @override
  void onInit() {
    super.onInit();
    player = Player();
    videoController = VideoController(player);
  }

  @override
  void onClose() {
    player.dispose();
  }
}
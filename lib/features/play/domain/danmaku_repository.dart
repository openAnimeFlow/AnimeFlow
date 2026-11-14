import 'package:anime_flow/features/play/domain/danmaku_chinese_mode.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';

abstract interface class DanmakuConverter {
  Future<List<Danmaku>> convertDanmakus(
      List<Danmaku> items, DanmakuChineseMode mode);
}

abstract interface class DanmakuRepository {
  Future<List<Danmaku>> loadLocal(String? path);
  Future<List<Danmaku>> loadEpisode(
      {required int subjectId, required int episodeId});
  Future<List<Danmaku>> loadAlternative(int episodeId);
  Future<void> send(int subjectId, int episodeId, Danmaku item);
}

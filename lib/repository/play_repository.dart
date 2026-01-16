import 'package:anime_flow/models/item/play/play_history.dart';
import 'package:anime_flow/repository/storage.dart';

class PlayRepository {
  static final playHistory = Storage.playHistory;

  /// playId = subjectId + episodeId
  static Future<void> savePlayPosition(
      String playId, Duration position, Duration duration) async {
    if (duration - position < const Duration(seconds: 20)) return;

    final data = PlayHistory(
      playId: playId,
      position: position.inSeconds,
      duration: duration.inSeconds,
      updateAt: DateTime.now().millisecondsSinceEpoch,
    );
    await playHistory.put(playId, data);
    await trimToLimit();
  }

  ///检查进度是否存在
  static Future<bool> checkPlayPosition(String playId) async {
    return playHistory.containsKey(playId);
  }

  ///读取进度
  static Future<PlayHistory?> getPlayPosition(String playId) async {
    return playHistory.get(playId);
  }

  ///删除进度
  static Future<void> deletePlayPosition(String playId) async {
    return playHistory.delete(playId);
  }

  static Future<void> trimToLimit({int max = 50}) async {
    final list = playHistory.values.toList();
    if (list.length <= max) {
      return;
    } else {
      list.sort((a, b) => b.updateAt.compareTo(a.updateAt));

      final recordsToDelete = list.skip(max - 20).take(20).toList();

      for (final p in recordsToDelete) {
        await p.delete();
      }
    }
  }
}

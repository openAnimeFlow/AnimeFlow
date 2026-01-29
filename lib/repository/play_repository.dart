import 'package:anime_flow/models/item/play/play_history.dart';
import 'package:anime_flow/models/item/play/play_position.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:hive/hive.dart';

class PlayRepository {
  static final playPositionStorage = Storage.playPosition;
  static final playHistoryStorage = Storage.playHistory;
  /// playId = subjectId + episodeId
  /// 保存播放进度
  static Future<void> savePlayPosition(
      String playId, Duration position, Duration duration) async {
    if (duration < const Duration(seconds: 2) ||
        duration - position < const Duration(seconds: 20)) {
      return;
    }

    final data = PlayPosition(
      playId: playId,
      position: position.inSeconds,
      duration: duration.inSeconds,
      updateAt: DateTime.now().millisecondsSinceEpoch,
    );
    await playPositionStorage.put(playId, data);
    await _trimToLimit<PlayPosition>(
      playPositionStorage,
          (a, b) => b.updateAt.compareTo(a.updateAt),
    );
  }

  ///读取进度
  static Future<PlayPosition?> getPlayPosition(String playId) async {
    return playPositionStorage.get(playId);
  }

  ///删除进度
  static Future<void> deletePlayPosition(String playId) async {
    return playPositionStorage.delete(playId);
  }

  /// 保存播放历史
  static Future<void> savePlayHistory(PlayHistory playHistory) async {
    await playHistoryStorage.put(playHistory.subjectId, playHistory);
    await _trimToLimit<PlayHistory>(
      playHistoryStorage,
          (a, b) => b.playTime.compareTo(a.playTime),
    );
  }

  /// 限制存储数量
  /// [box] 存储盒子
  /// [compare] 比较函数，用于排序（返回负数表示 a < b，正数表示 a > b）
  /// [max] 最大保存数量，默认50条
  static Future<void> _trimToLimit<T extends HiveObject>(
      Box<T> box,
      int Function(T, T) compare, {
        int max = 50,
      }) async {
    final list = box.values.toList();
    if (list.length <= max) {
      return;
    } else {
      list.sort(compare);

      final recordsToDelete = list.skip(max - 20).take(20).toList();

      for (final p in recordsToDelete) {
        await p.delete();
      }
    }
  }
}

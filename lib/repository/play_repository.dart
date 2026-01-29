import 'package:anime_flow/models/item/play/play_history.dart';
import 'package:anime_flow/repository/storage.dart';
import 'package:hive/hive.dart';

class PlayRepository {
  static final playPositionStorage = Storage.playPosition;
  static final playHistoryStorage = Storage.playHistory;

  /// 保存播放记录
  static Future<void> savePlayHistory(PlayHistory playHistory) async {
    await playHistoryStorage.put(playHistory.subjectId, playHistory);
    await _trimToLimit<PlayHistory>(
      playHistoryStorage,
          (a, b) => b.updateAt.compareTo(a.updateAt),
    );
  }

  /// 读取播放记录
  static Future<PlayHistory?> getPlayHistory(int subjectId) async {
    return playHistoryStorage.get(subjectId);
  }

  /// 删除播放记录中的播放进度
  static Future<void> deletePlayHistoryByPosition(int subjectId) async {
    final playHistory = await getPlayHistory(subjectId);
    if (playHistory != null) {
      playHistory.position = 0;
      playHistory.duration = 0;
      await playHistory.save();
    }
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

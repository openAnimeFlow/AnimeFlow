import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/models/item/play/play_history.dart';
import 'package:anime_flow/models/item/play/play_position.dart';
import 'package:hive/hive.dart';

class Storage {
  static late final Box<dynamic> setting;
  static late final Box<dynamic> crawlConfigs;
  static late final Box<PlayHistory> playHistory;

  static Future init() async {
    Hive.registerAdapter(PlayPositionAdapter());
    Hive.registerAdapter(PlayHistoryAdapter());
    crawlConfigs = await Hive.openBox(StorageKey.crawlConfigs);
    setting = await Hive.openBox(StorageKey.settingsKey);
    playHistory = await _openBoxWithFallback<PlayHistory>(StorageKey.playHistoryKey);
  }

  /// 打开 Box，如果失败则删除并重新创建
  static Future<Box<T>> _openBoxWithFallback<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      // 先关闭 box（如果已打开），释放文件锁
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      // 删除损坏的数据文件
      await Hive.deleteBoxFromDisk(boxName);
      return await Hive.openBox<T>(boxName);
    }
  }
}

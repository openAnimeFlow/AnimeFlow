import 'package:anime_flow/constants/storage_key.dart';
import 'package:anime_flow/hive_registrar.g.dart';
import 'package:anime_flow/models/play/play_history.dart';
import 'package:hive_ce/hive.dart';

class Storage {
  static late final Box<dynamic> setting;
  static late final Box<dynamic> crawlConfigs;
  static late final Box<PlayHistory> playHistory;
  static late final Box<String> searchHistory;

  static Future init() async {
    /// 通过 hive_registrar.g.dart 统一注册所有已生成的 Hive TypeAdapter。
    Hive.registerAdapters();
    crawlConfigs = await _openBoxWithFallback<dynamic>(StorageKey.crawlConfigs);
    setting = await _openBoxWithFallback<dynamic>(StorageKey.settingsKey);
    playHistory = await _openBoxWithFallback<PlayHistory>(StorageKey.playHistoryKey);
    searchHistory = await _openBoxWithFallback<String>(StorageKey.searchHistoryKey);
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

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
    playHistory = await Hive.openBox(StorageKey.playHistoryKey);
  }
}

import 'package:anime_flow/constants/constants.dart';
import 'package:hive/hive.dart';

class Storage {
  static late final Box<dynamic> setting;
  static late final Box<dynamic> crawlConfigs;

  static Future init() async {
    crawlConfigs = await Hive.openBox(Constants.crawlConfigs);
    setting = await Hive.openBox(Constants.settingsKey);
  }
}

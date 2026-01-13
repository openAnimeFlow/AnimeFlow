import 'package:anime_flow/constants/constants.dart';
import 'package:hive/hive.dart';

class Storage {
  static late final Box<dynamic> setting;

  static Future init() async {
    await Hive.openBox(Constants.crawlConfigs);
    setting = await Hive.openBox(Constants.settingsKey);
  }
 }
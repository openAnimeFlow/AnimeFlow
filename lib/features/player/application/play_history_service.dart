import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/features/player/data/repository/play_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// 播放历史的业务入口，供 player 内外的页面使用。
class PlayHistoryService {
  const PlayHistoryService._();

  static ValueListenable<Box<PlayHistory>> listenable() =>
      PlayRepository.playHistoryStorage.listenable();

  static Future<List<PlayHistory>> getAll() =>
      PlayRepository.getPlayHistoryList();

  static Future<PlayHistory?> getBySubjectId(int subjectId) =>
      PlayRepository.getPlayHistory(subjectId);

  static Future<void> save(PlayHistory history) =>
      PlayRepository.savePlayHistory(history);

  static Future<void> clearPosition(int subjectId) =>
      PlayRepository.deletePlayHistoryByPosition(subjectId);
}

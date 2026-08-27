import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:hive_ce/hive.dart';

part 'download_record.g.dart';

@HiveType(typeId: 10)
class DownloadRecord {
  @HiveField(0)
  int subjectId;

  @HiveField(1)
  String subjectName;

  @HiveField(2)
  String subjectCover;

  @HiveField(3)
  String sourceName;

  @HiveField(4)
  String sourceBaseUrl;

  @HiveField(5)
  Map<String, DownloadEpisode> episodes;

  @HiveField(6)
  DateTime createdAt;

  DownloadRecord({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCover,
    required this.sourceName,
    required this.sourceBaseUrl,
    required this.episodes,
    required this.createdAt,
  });

  String get key => buildKey(sourceName: sourceName, subjectId: subjectId);

  static String buildKey({
    required String sourceName,
    required int subjectId,
  }) {
    return '${sourceName}_$subjectId';
  }
}

import 'download_episode.dart';

class DownloadRecord {
  int subjectId;

  String subjectName;

  String subjectCover;

  String sourceName;

  String sourceBaseUrl;

  Map<String, DownloadEpisode> episodes;

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

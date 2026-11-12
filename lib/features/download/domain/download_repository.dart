import 'download_episode.dart';
import 'download_record.dart';

abstract interface class IDownloadRepository {
  List<DownloadRecord> getAllRecords();

  DownloadRecord? getRecord(String key);

  Future<void> putRecord(DownloadRecord record);

  Future<void> updateEpisode(
    String recordKey,
    String episodeUrl,
    DownloadEpisode episode,
  );

  /// Flushes metadata changes on an existing episode, even if its status is unchanged.
  Future<void> persistEpisodeMetadata(
    String recordKey,
    String episodeUrl,
    DownloadEpisode episode,
  );

  Future<void> deleteEpisode(String recordKey, String episodeUrl);

  List<DownloadEpisode> getCompletedEpisodes(
    int subjectId,
    String sourceName,
  );

  DownloadEpisode? getEpisode(
    int subjectId,
    String sourceName,
    String episodeUrl,
  );
}

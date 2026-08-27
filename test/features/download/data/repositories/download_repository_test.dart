import 'dart:io';

import 'package:anime_flow/features/download/data/repositories/download_repository.dart';
import 'package:anime_flow/hive_registrar.g.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;
  late Box<DownloadRecord> box;
  late DownloadRepository repository;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('anime_flow_download_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    box = await Hive.openBox<DownloadRecord>('downloads_test');
    await box.clear();
    repository = DownloadRepository(storage: box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('downloads_test');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DownloadRepository', () {
    test('stores and reads download records by record key', () async {
      final record = _record(
        subjectId: 1,
        sourceName: 'source',
        episode: _episode(url: 'https://example.com/1'),
      );

      await repository.putRecord(record);

      expect(repository.getRecord(record.key)?.subjectName, 'Subject 1');
      expect(repository.getEpisode(1, 'source', 'https://example.com/1'),
          isNotNull);
    });

    test('updates and deletes episodes in a record', () async {
      final record = _record(
        subjectId: 1,
        sourceName: 'source',
        episode: _episode(url: 'https://example.com/1'),
      );
      await repository.putRecord(record);

      await repository.updateEpisode(
        record.key,
        'https://example.com/2',
        _episode(url: 'https://example.com/2'),
      );

      expect(repository.getRecord(record.key)?.episodes.length, 2);

      await repository.deleteEpisode(record.key, 'https://example.com/1');
      expect(repository.getRecord(record.key)?.episodes.length, 1);

      await repository.deleteEpisode(record.key, 'https://example.com/2');
      expect(repository.getRecord(record.key), isNull);
    });

    test('exposes same-status progress through repository cache', () async {
      final record = _record(
        subjectId: 1,
        sourceName: 'source',
        episode: _episode(url: 'https://example.com/1'),
      );
      await repository.putRecord(record);

      await repository.updateEpisode(
        record.key,
        'https://example.com/1',
        _episode(url: 'https://example.com/1')..progressPercent = 42,
      );

      expect(
        repository
            .getRecord(record.key)
            ?.episodes['https://example.com/1']
            ?.progressPercent,
        42,
      );
    });

    test('persists episode when status changes', () async {
      final record = _record(
        subjectId: 1,
        sourceName: 'source',
        episode: _episode(url: 'https://example.com/1'),
      );
      await repository.putRecord(record);

      await repository.updateEpisode(
        record.key,
        'https://example.com/1',
        _episode(
          url: 'https://example.com/1',
          status: DownloadStatus.completed,
        )..progressPercent = 100,
      );

      expect(
        box.get(record.key)?.episodes['https://example.com/1']?.status,
        DownloadStatus.completed,
      );
    });

    test('returns completed episodes ordered by line then episode sort',
        () async {
      final record = DownloadRecord(
        subjectId: 1,
        subjectName: 'Subject 1',
        subjectCover: '',
        sourceName: 'source',
        sourceBaseUrl: 'https://example.com',
        createdAt: DateTime(2026),
        episodes: {
          'ep2': _episode(
            url: 'ep2',
            sort: 2,
            lineIndex: 0,
            status: DownloadStatus.completed,
          ),
          'ep1': _episode(
            url: 'ep1',
            sort: 1,
            lineIndex: 0,
            status: DownloadStatus.completed,
          ),
          'line2': _episode(
            url: 'line2',
            sort: 1,
            lineIndex: 1,
            status: DownloadStatus.completed,
          ),
          'pending': _episode(
            url: 'pending',
            sort: 3,
            lineIndex: 0,
            status: DownloadStatus.pending,
          ),
        },
      );
      await repository.putRecord(record);

      final episodes = repository.getCompletedEpisodes(1, 'source');

      expect(episodes.map((episode) => episode.episodeUrl),
          ['ep1', 'ep2', 'line2']);
    });
  });
}

DownloadRecord _record({
  required int subjectId,
  required String sourceName,
  required DownloadEpisode episode,
}) {
  return DownloadRecord(
    subjectId: subjectId,
    subjectName: 'Subject $subjectId',
    subjectCover: '',
    sourceName: sourceName,
    sourceBaseUrl: 'https://example.com',
    episodes: {episode.episodeUrl: episode},
    createdAt: DateTime(2026),
  );
}

DownloadEpisode _episode({
  required String url,
  double sort = 1,
  int lineIndex = 0,
  int status = DownloadStatus.pending,
}) {
  return DownloadEpisode(
    episodeUrl: url,
    bangumiEpisodeId: 100,
    episodeSort: sort,
    episodeIndex: sort.toInt(),
    episodeTitle: 'Episode $sort',
    lineIndex: lineIndex,
    sourceName: 'source',
    status: status,
  );
}

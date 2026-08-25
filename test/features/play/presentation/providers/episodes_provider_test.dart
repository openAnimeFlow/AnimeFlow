import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Episodes offline mode', () {
    test('builds episodes from completed download snapshot', () async {
      final container = ProviderContainer(
        overrides: [
          playExtraProvider.overrideWithValue(
            PlayRouteExtra(
              playExtra: const PlayExtra(
                subjectId: 1,
                subjectName: 'Subject',
                subjectCover: 'cover',
                subjectAliases: ['Alias'],
              ),
              continueEpisodeId: 102,
              isOfflineMode: true,
              offlineMediaPath: '/tmp/ep2.m3u8',
              offlineEpisodeUrl: 'ep2',
              offlineEpisodes: [
                _episode(
                  episodeUrl: 'ep2',
                  bangumiEpisodeId: 102,
                  episodeSort: 2,
                  episodeIndex: 2,
                  episodeTitle: 'Episode 2',
                  localMediaPath: '/tmp/ep2.m3u8',
                  status: DownloadStatus.completed,
                ),
                _episode(
                  episodeUrl: 'ep1',
                  bangumiEpisodeId: 101,
                  episodeSort: 1,
                  episodeIndex: 1,
                  episodeTitle: 'Episode 1',
                  localMediaPath: '/tmp/ep1.m3u8',
                  status: DownloadStatus.completed,
                ),
                _episode(
                  episodeUrl: 'ep3',
                  bangumiEpisodeId: 103,
                  episodeSort: 3,
                  episodeIndex: 3,
                  episodeTitle: 'Episode 3',
                  localMediaPath: '/tmp/ep3.m3u8',
                  status: DownloadStatus.downloading,
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(episodesProvider.future);

      expect(data.subjectId, 1);
      expect(data.episodeTitle, 'Episode 2');
      expect(data.episodeIndex, 2);
      expect(data.episodeId, 102);
      expect(data.hasMore, isFalse);
      expect(data.episodes?.total, 2);
      expect(
        data.episodes?.data.map((episode) => episode.nameCN),
        ['Episode 1', 'Episode 2'],
      );
    });
  });
}

DownloadEpisode _episode({
  required String episodeUrl,
  required int bangumiEpisodeId,
  required double episodeSort,
  required int episodeIndex,
  required String episodeTitle,
  required String localMediaPath,
  required int status,
}) {
  return DownloadEpisode(
    episodeUrl: episodeUrl,
    bangumiEpisodeId: bangumiEpisodeId,
    episodeSort: episodeSort,
    episodeIndex: episodeIndex,
    episodeTitle: episodeTitle,
    lineIndex: 0,
    sourceName: 'source',
    status: status,
    localMediaPath: localMediaPath,
  );
}

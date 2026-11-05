import 'package:anime_flow/features/play/infrastructure/source/webview_captcha_session.dart';
import 'package:anime_flow/features/play/infrastructure/player/native_playback_device.dart';
import 'package:anime_flow/features/play/infrastructure/source/crawler_source_repository.dart';
import 'package:anime_flow/features/source/application/providers/source_repository_provider.dart';
import 'package:anime_flow/features/play/infrastructure/queries/flow_play_queries.dart';
import 'package:anime_flow/features/play/infrastructure/player/native_playback_platform.dart';
import 'package:anime_flow/features/play/infrastructure/settings/stored_play_preferences.dart';
import 'package:anime_flow/features/play/infrastructure/history/hive_play_history_repository.dart';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/play/infrastructure/danmaku/flow_danmaku_repository.dart';
import 'package:anime_flow/features/play/infrastructure/danmaku/opencc_converter.dart';
import 'package:anime_flow/features/play/infrastructure/player/player_video_surface.dart';

final playFeatureOverrides = [
  playHistoryRepositoryProvider
      .overrideWith((ref) => HivePlayHistoryRepository()),
  playPreferencesProvider.overrideWith((ref) => StoredPlayPreferences()),
  playbackPlatformProvider.overrideWith((ref) => NativePlaybackPlatform()),
  playQueriesProvider.overrideWith((ref) => FlowPlayQueries()),
  playSourceRepositoryProvider.overrideWith((ref) =>
      CrawlerSourceRepository(ref.watch(sourceRepositoryProvider).getSources)),
  playbackDeviceProvider.overrideWith((ref) => NativePlaybackDevice()),
  captchaSessionFactoryProvider
      .overrideWith((ref) => WebviewCaptchaSession.new),
  danmakuRepositoryProvider.overrideWith((ref) => FlowDanmakuRepository()),
  danmakuConverterProvider.overrideWith((ref) {
    final converter = DanmakuChineseConverter();
    ref.onDispose(converter.dispose);
    return converter;
  }),
  markWatchedProvider.overrideWith((ref) => FlowPlayQueries.markEpisodeWatched),
  playerSurfaceProvider.overrideWith((ref) => (engine, fit) =>
      (engine as PlayerVideoSurface).buildVideoSurface(fit: fit)),
];

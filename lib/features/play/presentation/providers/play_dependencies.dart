import 'package:anime_flow/features/play/domain/danmaku_repository.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/application/playback_progress_manager.dart';
import 'package:anime_flow/core/video_source/domain/captcha_session.dart';
import 'package:anime_flow/features/play/domain/playback_device.dart';
import 'package:anime_flow/features/play/domain/play_source_repository.dart';
import 'package:anime_flow/features/play/domain/play_queries.dart';
import 'package:anime_flow/features/play/domain/playback_platform.dart';
import 'package:anime_flow/features/play/domain/play_preferences.dart';
import 'package:anime_flow/features/play/domain/play_history_repository.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

typedef PlayerSurfaceBuilder = Widget Function(PlayerEngine engine, BoxFit fit);

Provider<T> _dependency<T>(String name) =>
    Provider<T>((ref) => throw StateError(
        '$name must be supplied by the playback composition root'));
final playHistoryRepositoryProvider =
    _dependency<PlayHistoryRepository>('playHistoryRepositoryProvider');
final playHistoryServiceProvider = Provider<PlayHistoryService>(
    (ref) => PlayHistoryService(ref.watch(playHistoryRepositoryProvider)));
final playPreferencesProvider =
    _dependency<PlayPreferences>('playPreferencesProvider');
final playbackPlatformProvider =
    _dependency<PlaybackPlatform>('playbackPlatformProvider');
final playQueriesProvider = _dependency<PlayQueries>('playQueriesProvider');
final playSourceRepositoryProvider =
    _dependency<PlaySourceRepository>('playSourceRepositoryProvider');
final playbackDeviceProvider =
    _dependency<PlaybackDevice>('playbackDeviceProvider');
final captchaSessionFactoryProvider =
    _dependency<CaptchaSession Function()>('captchaSessionFactoryProvider');
final danmakuRepositoryProvider =
    _dependency<DanmakuRepository>('danmakuRepositoryProvider');
final danmakuConverterProvider =
    _dependency<DanmakuConverter>('danmakuConverterProvider');
final markWatchedProvider =
    _dependency<MarkEpisodeWatched>('markWatchedProvider');
final playerSurfaceProvider =
    _dependency<PlayerSurfaceBuilder>('playerSurfaceProvider');
final playerEngineFactoryProvider =
    _dependency<PlayerEngineFactory>('playerEngineFactoryProvider');

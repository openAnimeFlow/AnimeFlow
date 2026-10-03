import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/play/application/playback_progress_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// 内存设置箱，避免测试依赖 Hive 初始化。
class _Settings implements Box<dynamic> {
  final stored = <dynamic, dynamic>{};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      stored[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async {
    stored[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// 构造一个把「标记已看」替换成记录到 [marked] 的管理器。
PlaybackProgressManager _manager(List<int> marked) {
  return PlaybackProgressManager(
    onEpisodeWatched: ({
      required int subjectId,
      required int episodeId,
      required bool watched,
    }) {},
    markEpisodeWatched: (episodeId) async => marked.add(episodeId),
  );
}

void _useSubject(
  PlaybackProgressManager manager, {
  bool isLocalPlayback = false,
}) {
  manager.setPlaybackContext(
    subjectId: 1,
    episodeId: 10,
    episodeSort: 1,
    subjectName: '葬送的芙莉莲',
    subjectCover: 'https://example.com/cover.jpg',
    alias: const [],
    isLocalPlayback: isLocalPlayback,
  );
}

void main() {
  setUpAll(() {
    Storage.setting = _Settings();
  });

  setUp(() async {
    await AppSettings.setEpisodesProgress(true);
  });

  group('自动标记已看', () {
    test('进度达到阈值时标记当前剧集', () async {
      final marked = <int>[];
      final manager = _manager(marked);
      _useSubject(manager);

      manager.updatePlaybackState(
        position: const Duration(minutes: 3),
        duration: const Duration(minutes: 3),
        playing: true,
        isLoggedIn: true,
      );
      await pumpEventQueue();

      expect(marked, [10]);
    });

    test('总时长小于 2 分钟时不标记，即使已经播完', () async {
      final marked = <int>[];
      final manager = _manager(marked);
      _useSubject(manager);

      manager.updatePlaybackState(
        position: const Duration(seconds: 110),
        duration: const Duration(seconds: 110),
        playing: true,
        isLoggedIn: true,
      );
      await pumpEventQueue();

      expect(marked, isEmpty);
    });

    test('总时长刚好到 2 分钟时仍然参与判断', () async {
      final marked = <int>[];
      final manager = _manager(marked);
      _useSubject(manager);

      manager.updatePlaybackState(
        position: PlaybackProgressManager.minDurationForAutoWatched,
        duration: PlaybackProgressManager.minDurationForAutoWatched,
        playing: true,
        isLoggedIn: true,
      );
      await pumpEventQueue();

      expect(marked, [10]);
    });

    test('进度低于阈值时不标记', () async {
      final marked = <int>[];
      final manager = _manager(marked);
      _useSubject(manager);

      manager.updatePlaybackState(
        position: const Duration(minutes: 2),
        duration: const Duration(minutes: 5),
        playing: true,
        isLoggedIn: true,
      );
      await pumpEventQueue();

      expect(marked, isEmpty);
    });

    test('同一集只标记一次', () async {
      final marked = <int>[];
      final manager = _manager(marked);
      _useSubject(manager);

      for (var i = 0; i < 3; i++) {
        manager.updatePlaybackState(
          position: const Duration(minutes: 4),
          duration: const Duration(minutes: 4),
          playing: true,
          isLoggedIn: true,
        );
        await pumpEventQueue();
      }

      expect(marked, [10]);
    });

    test('未登录或未播放时不标记', () async {
      final marked = <int>[];
      final manager = _manager(marked);
      _useSubject(manager);

      manager.updatePlaybackState(
        position: const Duration(minutes: 4),
        duration: const Duration(minutes: 4),
        playing: false,
        isLoggedIn: true,
      );
      manager.updatePlaybackState(
        position: const Duration(minutes: 4),
        duration: const Duration(minutes: 4),
        playing: true,
        isLoggedIn: false,
      );
      await pumpEventQueue();

      expect(marked, isEmpty);
    });

    test('本地播放不标记', () async {
      final marked = <int>[];
      final manager = _manager(marked);
      _useSubject(manager, isLocalPlayback: true);

      manager.updatePlaybackState(
        position: const Duration(minutes: 4),
        duration: const Duration(minutes: 4),
        playing: true,
        isLoggedIn: true,
      );
      await pumpEventQueue();

      expect(marked, isEmpty);
    });

    test('设置里关闭「保存剧集进度」后不标记', () async {
      await AppSettings.setEpisodesProgress(false);
      final marked = <int>[];
      final manager = _manager(marked);
      _useSubject(manager);

      manager.updatePlaybackState(
        position: const Duration(minutes: 4),
        duration: const Duration(minutes: 4),
        playing: true,
        isLoggedIn: true,
      );
      await pumpEventQueue();

      expect(marked, isEmpty);
    });
  });
}

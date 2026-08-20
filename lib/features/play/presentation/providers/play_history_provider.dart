import 'dart:async';

import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/features/play/data/repository/play_repository.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'play_history_provider.g.dart';

/// 播放记录的统一入口，负责读取列表并在本地数据变化后自动刷新。
@Riverpod(keepAlive: true)
class PlayHistoryController extends _$PlayHistoryController {
  ValueListenable<Box<PlayHistory>>? _historyListenable;
  Future<void> _operationQueue = Future<void>.value();
  bool _autoSyncQueuedOrRunning = false;

  @override
  Future<List<PlayHistory>> build() async {
    _historyListenable = PlayHistoryService.listenable();
    _historyListenable?.addListener(_reload);
    ref.onDispose(() {
      _historyListenable?.removeListener(_reload);
      _historyListenable = null;
    });
    ref.listen<AsyncValue<bool>>(
      isLoggedInProvider,
      (previous, next) {
        final wasLoggedIn = previous?.value ?? false;
        final isLoggedIn = next.value ?? false;
        if (previous != null && isLoggedIn && !wasLoggedIn) {
          unawaited(autoSyncFromServer());
        }
      },
    );
    unawaited(autoSyncFromServer());
    try {
      return await _fetch();
    } catch (e) {
      LiggLogger().e(e);
      rethrow;
    }
  }

  Future<List<PlayHistory>> _fetch() async {
    final histories = await PlayHistoryService.getAll();
    histories.sort((a, b) => b.updateAt.compareTo(a.updateAt));
    return histories;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> _reload() async {
    try {
      final histories = await _fetch();
      if (ref.mounted) {
        state = AsyncData(histories);
      }
    } catch (e) {
      LiggLogger().e(e);
    }
  }

  /// 上传本地未同步的播放记录。
  Future<PlayHistorySyncResult> syncPending() {
    return _enqueue(_syncPendingOnly);
  }

  Future<PlayHistorySyncResult> _syncPendingOnly() async {
    final result = await PlayHistoryService.syncPending();
    await _reload();
    return result;
  }

  /// 清空本地播放记录。
  Future<void> clearLocal() {
    return _enqueue(_clearLocalOnly);
  }

  Future<void> _clearLocalOnly() async {
    await PlayHistoryService.clearLocal();
    await _reload();
  }

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  /// 自动同步：先上传本地未同步记录，再拉取服务器记录并刷新列表。
  Future<void> autoSyncFromServer() {
    if (_autoSyncQueuedOrRunning) return Future<void>.value();
    _autoSyncQueuedOrRunning = true;
    return _enqueue(_autoSync).whenComplete(() {
      _autoSyncQueuedOrRunning = false;
    });
  }

  Future<void> _autoSync() async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _syncPendingOnly();
        await PlayHistoryService.syncFromServer();
        await _reload();
        return;
      } catch (e) {
        LiggLogger().e('自动同步播放记录失败(第 $attempt/$maxAttempts 次): $e');
        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    NotificationToast.show('播放记录自动同步失败，请稍后重试', title: '提示');
  }
}

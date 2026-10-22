import 'dart:async';

import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';
import 'package:anime_flow/features/play/data/repository/play_repository.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/shared/models/player/play/play_history.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'play_history_provider.g.dart';

/// 同步失败时保留本地记录，错误由页面决定如何展示。
class PlayHistoryState {
  const PlayHistoryState({required this.records, this.syncError});

  final List<PlayHistory> records;
  final Object? syncError;
}

/// 播放记录列表状态与同步入口。
///
/// 持久化和远程同步由 [PlayHistoryService] 负责，本类只负责将结果
/// 暴露为 Riverpod 状态，并在本地数据变化后刷新列表。
@Riverpod(keepAlive: true)
class PlayHistoryNotifier extends _$PlayHistoryNotifier {
  ValueListenable<Box<PlayHistory>>? _historyListenable;
  Future<void> _operationQueue = Future<void>.value();
  bool _autoSyncQueuedOrRunning = false;

  @override
  Future<PlayHistoryState> build() async {
    _historyListenable = PlayHistoryService.listenable()
      ..addListener(_reloadState);
    ref.onDispose(() {
      _historyListenable?.removeListener(_reloadState);
      _historyListenable = null;
    });
    ref.listen<AsyncValue<bool>>(
      isLoggedInProvider,
      (previous, next) {
        final wasLoggedIn = previous?.value ?? false;
        final isLoggedIn = next.value ?? false;
        if (previous != null && isLoggedIn && !wasLoggedIn) {
          unawaited(syncFromServer());
        }
      },
    );
    unawaited(syncFromServer());
    try {
      return await _loadHistories();
    } catch (e) {
      LiggLogger().e(e);
      rethrow;
    }
  }

  Future<PlayHistoryState> _loadHistories() async {
    final histories = await PlayHistoryService.getAll();
    histories.sort((a, b) => b.updateAt.compareTo(a.updateAt));
    return PlayHistoryState(records: histories);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(_loadHistories);
    if (ref.mounted) state = result;
  }

  Future<void> _reloadState() async {
    try {
      final histories = await _loadHistories();
      if (ref.mounted) {
        state = AsyncData(histories);
      }
    } catch (e) {
      LiggLogger().e(e);
    }
  }

  /// 上传本地未同步的播放记录。
  Future<PlayHistorySyncResult> syncPending() {
    return _enqueue(_syncPendingAndRefresh);
  }

  Future<PlayHistorySyncResult> _syncPendingAndRefresh() async {
    final result = await PlayHistoryService.syncPending();
    await _reloadState();
    return result;
  }

  /// 清空本地播放记录。
  Future<void> clearLocal() {
    return _enqueue(_clearLocalOnly);
  }

  Future<void> _clearLocalOnly() async {
    await PlayHistoryService.clearLocal();
    await _reloadState();
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
  Future<void> syncFromServer() {
    if (_autoSyncQueuedOrRunning) return Future<void>.value();
    _autoSyncQueuedOrRunning = true;
    return _enqueue(_syncFromServer).whenComplete(() {
      _autoSyncQueuedOrRunning = false;
    });
  }

  Future<void> _syncFromServer() async {
    const maxAttempts = 3;
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (!ref.mounted) return;
      try {
        await _syncPendingAndRefresh();
        if (!ref.mounted) return;
        await PlayHistoryService.syncFromServer();
        await _reloadState();
        return;
      } catch (e) {
        lastError = e;
        if (!ref.mounted) return;
        LiggLogger().e('自动同步播放记录失败(第 $attempt/$maxAttempts 次): $e');
        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    if (ref.mounted && lastError != null) {
      state = AsyncData(PlayHistoryState(
        records: state.value?.records ?? const [],
        syncError: lastError,
      ));
    }
  }
}

import 'package:anime_flow/core/logger/app_log.dart';
import 'dart:async';
import 'package:anime_flow/features/play/presentation/providers/play_dependencies.dart';
import 'package:anime_flow/features/play/domain/play_history_repository.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'play_history_provider.g.dart';

/// 同步失败时保留本地记录，错误由页面决定如何展示。
class PlayHistoryState {
  const PlayHistoryState({required this.records, this.syncError});

  final List<PlaybackRecord> records;
  final Object? syncError;
}

/// 播放记录列表状态与同步入口。
///
/// 持久化和远程同步由 [PlayHistoryService] 负责，本类只负责将结果
/// 暴露为 Riverpod 状态，并在本地数据变化后刷新列表。
@Riverpod(keepAlive: true)
class PlayHistoryNotifier extends _$PlayHistoryNotifier {
  @override
  Future<PlayHistoryState> build() async {
    final changes = ref
        .watch(playHistoryServiceProvider)
        .changes
        .listen((_) => _reloadState());
    ref.onDispose(changes.cancel);
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
      logError(e);
      rethrow;
    }
  }

  Future<PlayHistoryState> _loadHistories() async {
    final histories = await ref.read(playHistoryServiceProvider).records();
    return PlayHistoryState(records: histories);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(_loadHistories);
    if (ref.mounted) state = result;
  }

  Future<void> _reloadState() async {
    if (!ref.mounted) return;
    try {
      final histories = await _loadHistories();
      if (ref.mounted) {
        state = AsyncData(histories);
      }
    } catch (e) {
      logError(e);
    }
  }

  /// 上传本地未同步的播放记录。
  Future<PlayHistorySyncResult> syncPending() async {
    final result = await ref.read(playHistoryServiceProvider).syncPending();
    if (ref.mounted) await _reloadState();
    return result;
  }

  /// 清空本地播放记录。
  Future<void> clearLocal() async {
    await ref.read(playHistoryServiceProvider).clearLocal();
    if (ref.mounted) await _reloadState();
  }

  Future<void> syncFromServer() async {
    try {
      await ref
          .read(playHistoryServiceProvider)
          .synchronize(active: () => ref.mounted);
      if (ref.mounted) await _reloadState();
    } catch (error) {
      if (ref.mounted) {
        state = AsyncData(PlayHistoryState(
            records: state.value?.records ?? const [], syncError: error));
      }
    }
  }
}

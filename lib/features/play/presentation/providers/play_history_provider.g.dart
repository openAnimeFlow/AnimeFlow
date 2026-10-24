// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放记录列表状态与同步入口。
///
/// 持久化和远程同步由 [PlayHistoryService] 负责，本类只负责将结果
/// 暴露为 Riverpod 状态，并在本地数据变化后刷新列表。

@ProviderFor(PlayHistoryNotifier)
final playHistoryProvider = PlayHistoryNotifierProvider._();

/// 播放记录列表状态与同步入口。
///
/// 持久化和远程同步由 [PlayHistoryService] 负责，本类只负责将结果
/// 暴露为 Riverpod 状态，并在本地数据变化后刷新列表。
final class PlayHistoryNotifierProvider
    extends $AsyncNotifierProvider<PlayHistoryNotifier, PlayHistoryState> {
  /// 播放记录列表状态与同步入口。
  ///
  /// 持久化和远程同步由 [PlayHistoryService] 负责，本类只负责将结果
  /// 暴露为 Riverpod 状态，并在本地数据变化后刷新列表。
  PlayHistoryNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playHistoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playHistoryNotifierHash();

  @$internal
  @override
  PlayHistoryNotifier create() => PlayHistoryNotifier();
}

String _$playHistoryNotifierHash() =>
    r'fb8d6355223e9293a5b862cc59e39102702d5d12';

/// 播放记录列表状态与同步入口。
///
/// 持久化和远程同步由 [PlayHistoryService] 负责，本类只负责将结果
/// 暴露为 Riverpod 状态，并在本地数据变化后刷新列表。

abstract class _$PlayHistoryNotifier extends $AsyncNotifier<PlayHistoryState> {
  FutureOr<PlayHistoryState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PlayHistoryState>, PlayHistoryState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<PlayHistoryState>, PlayHistoryState>,
        AsyncValue<PlayHistoryState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

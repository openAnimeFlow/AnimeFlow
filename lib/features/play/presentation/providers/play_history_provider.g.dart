// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放记录的统一入口，负责读取列表并在本地数据变化后自动刷新。

@ProviderFor(PlayHistoryNotifier)
final playHistoryProvider = PlayHistoryNotifierProvider._();

/// 播放记录的统一入口，负责读取列表并在本地数据变化后自动刷新。
final class PlayHistoryNotifierProvider
    extends $AsyncNotifierProvider<PlayHistoryNotifier, List<PlayHistory>> {
  /// 播放记录的统一入口，负责读取列表并在本地数据变化后自动刷新。
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
    r'828a342c30429d68c2387ae00575e57432dfed19';

/// 播放记录的统一入口，负责读取列表并在本地数据变化后自动刷新。

abstract class _$PlayHistoryNotifier extends $AsyncNotifier<List<PlayHistory>> {
  FutureOr<List<PlayHistory>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PlayHistory>>, List<PlayHistory>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<PlayHistory>>, List<PlayHistory>>,
        AsyncValue<List<PlayHistory>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

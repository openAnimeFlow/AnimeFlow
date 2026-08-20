// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放记录的统一入口，负责读取列表并在本地数据变化后自动刷新。

@ProviderFor(PlayHistoryController)
final playHistoryControllerProvider = PlayHistoryControllerProvider._();

/// 播放记录的统一入口，负责读取列表并在本地数据变化后自动刷新。
final class PlayHistoryControllerProvider
    extends $AsyncNotifierProvider<PlayHistoryController, List<PlayHistory>> {
  /// 播放记录的统一入口，负责读取列表并在本地数据变化后自动刷新。
  PlayHistoryControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playHistoryControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playHistoryControllerHash();

  @$internal
  @override
  PlayHistoryController create() => PlayHistoryController();
}

String _$playHistoryControllerHash() =>
    r'926700c32dd73cb82f65414d9208ddf2a81584dd';

/// 播放记录的统一入口，负责读取列表并在本地数据变化后自动刷新。

abstract class _$PlayHistoryController
    extends $AsyncNotifier<List<PlayHistory>> {
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

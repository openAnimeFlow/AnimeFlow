// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 使用方式：`ref.watch(playProvider)` / `ref.read(playProvider.notifier)`。
/// [DanmakuController] 由弹幕组件创建后调用 [attachDanmakuController]。

@ProviderFor(PlayController)
final playControllerProvider = PlayControllerProvider._();

/// Riverpod 版播放控制逻辑。
///
/// 使用方式：`ref.watch(playProvider)` / `ref.read(playProvider.notifier)`。
/// [DanmakuController] 由弹幕组件创建后调用 [attachDanmakuController]。
final class PlayControllerProvider
    extends $NotifierProvider<PlayController, PlayState> {
  /// Riverpod 版播放控制逻辑。
  ///
  /// 使用方式：`ref.watch(playProvider)` / `ref.read(playProvider.notifier)`。
  /// [DanmakuController] 由弹幕组件创建后调用 [attachDanmakuController]。
  PlayControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playControllerHash();

  @$internal
  @override
  PlayController create() => PlayController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayState>(value),
    );
  }
}

String _$playControllerHash() => r'b2a349ac36abbae803101b8b47617aff10f98d40';

/// Riverpod 版播放控制逻辑。
///
/// 使用方式：`ref.watch(playProvider)` / `ref.read(playProvider.notifier)`。
/// [DanmakuController] 由弹幕组件创建后调用 [attachDanmakuController]。

abstract class _$PlayController extends $Notifier<PlayState> {
  PlayState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlayState, PlayState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PlayState, PlayState>, PlayState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

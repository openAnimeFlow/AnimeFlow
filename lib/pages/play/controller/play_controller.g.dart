// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playController)
final playControllerProvider = PlayControllerProvider._();

final class PlayControllerProvider
    extends $FunctionalProvider<PlayController, PlayController, PlayController>
    with $Provider<PlayController> {
  PlayControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playControllerProvider',
          isAutoDispose: false,
          dependencies: <ProviderOrFamily>[
            shadersDirectoryProvider,
            playStateControllerProvider,
            videoUiStateControllerProvider,
            playExtraProvider
          ],
          $allTransitiveDependencies: <ProviderOrFamily>{
            PlayControllerProvider.$allTransitiveDependencies0,
            PlayControllerProvider.$allTransitiveDependencies1,
            PlayControllerProvider.$allTransitiveDependencies2,
            PlayControllerProvider.$allTransitiveDependencies3,
          },
        );

  static final $allTransitiveDependencies0 = shadersDirectoryProvider;
  static final $allTransitiveDependencies1 = playStateControllerProvider;
  static final $allTransitiveDependencies2 = videoUiStateControllerProvider;
  static final $allTransitiveDependencies3 = playExtraProvider;

  @override
  String debugGetCreateSourceHash() => _$playControllerHash();

  @$internal
  @override
  $ProviderElement<PlayController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlayController create(Ref ref) {
    return playController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayController>(value),
    );
  }
}

String _$playControllerHash() => r'a77f839f454d9989c71e35b2c26fa897d8493bf1';

@ProviderFor(PlayStateController)
final playStateControllerProvider = PlayStateControllerProvider._();

final class PlayStateControllerProvider
    extends $NotifierProvider<PlayStateController, PlayControllerState> {
  PlayStateControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playStateControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playStateControllerHash();

  @$internal
  @override
  PlayStateController create() => PlayStateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayControllerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayControllerState>(value),
    );
  }
}

String _$playStateControllerHash() =>
    r'1fff7c88fd10c5615128eac17c9935cfe7433d60';

abstract class _$PlayStateController extends $Notifier<PlayControllerState> {
  PlayControllerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlayControllerState, PlayControllerState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PlayControllerState, PlayControllerState>,
        PlayControllerState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

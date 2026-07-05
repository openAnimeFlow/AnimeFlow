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
            episodesProvider,
            playExtraProvider
          ],
          $allTransitiveDependencies: <ProviderOrFamily>{
            PlayControllerProvider.$allTransitiveDependencies0,
            PlayControllerProvider.$allTransitiveDependencies1,
            PlayControllerProvider.$allTransitiveDependencies2,
            PlayControllerProvider.$allTransitiveDependencies3,
            PlayControllerProvider.$allTransitiveDependencies4,
          },
        );

  static final $allTransitiveDependencies0 = shadersDirectoryProvider;
  static final $allTransitiveDependencies1 = playStateControllerProvider;
  static final $allTransitiveDependencies2 =
      PlayStateControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 = videoUiStateControllerProvider;
  static final $allTransitiveDependencies4 = episodesProvider;

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

String _$playControllerHash() => r'0b448892d3463248efbae177c8f7ce20eee1f47f';

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
          dependencies: <ProviderOrFamily>[playExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            PlayStateControllerProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = playExtraProvider;

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
    r'93bba1a1b74d01d32637d2f6361a12c8caece34f';

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

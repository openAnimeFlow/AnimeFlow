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
            videoUiStateControllerProvider,
            playExtraProvider
          ],
          $allTransitiveDependencies: <ProviderOrFamily>[
            PlayControllerProvider.$allTransitiveDependencies0,
            PlayControllerProvider.$allTransitiveDependencies1,
            PlayControllerProvider.$allTransitiveDependencies2,
          ],
        );

  static final $allTransitiveDependencies0 = shadersDirectoryProvider;
  static final $allTransitiveDependencies1 = videoUiStateControllerProvider;
  static final $allTransitiveDependencies2 = playExtraProvider;

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

String _$playControllerHash() => r'7c667f5a545c042a28168376790f80b8d6503f2a';

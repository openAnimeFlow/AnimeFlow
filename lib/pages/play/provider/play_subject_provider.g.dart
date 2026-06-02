// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_subject_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playRouteExtra)
final playRouteExtraProvider = PlayRouteExtraProvider._();

final class PlayRouteExtraProvider
    extends $FunctionalProvider<PlayRouteExtra, PlayRouteExtra, PlayRouteExtra>
    with $Provider<PlayRouteExtra> {
  PlayRouteExtraProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playRouteExtraProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[],
          $allTransitiveDependencies: <ProviderOrFamily>[],
        );

  @override
  String debugGetCreateSourceHash() => _$playRouteExtraHash();

  @$internal
  @override
  $ProviderElement<PlayRouteExtra> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlayRouteExtra create(Ref ref) {
    return playRouteExtra(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayRouteExtra value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayRouteExtra>(value),
    );
  }
}

String _$playRouteExtraHash() => r'c793d3aac1dbd1a21ee5dbf7f555486b02da19f7';

@ProviderFor(playSubject)
final playSubjectProvider = PlaySubjectProvider._();

final class PlaySubjectProvider
    extends $FunctionalProvider<PlayExtra, PlayExtra, PlayExtra>
    with $Provider<PlayExtra> {
  PlaySubjectProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playSubjectProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[playSubjectStateProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            PlaySubjectProvider.$allTransitiveDependencies0,
            PlaySubjectProvider.$allTransitiveDependencies1,
          ],
        );

  static final $allTransitiveDependencies0 = playSubjectStateProvider;
  static final $allTransitiveDependencies1 =
      PlaySubjectStateProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$playSubjectHash();

  @$internal
  @override
  $ProviderElement<PlayExtra> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlayExtra create(Ref ref) {
    return playSubject(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayExtra value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayExtra>(value),
    );
  }
}

String _$playSubjectHash() => r'4f47f647ed6a2e974609834513f0536c4e7e5b5f';

@ProviderFor(playContinueEpisode)
final playContinueEpisodeProvider = PlayContinueEpisodeProvider._();

final class PlayContinueEpisodeProvider
    extends $FunctionalProvider<int, int, int> with $Provider<int> {
  PlayContinueEpisodeProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playContinueEpisodeProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[playSubjectStateProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            PlayContinueEpisodeProvider.$allTransitiveDependencies0,
            PlayContinueEpisodeProvider.$allTransitiveDependencies1,
          ],
        );

  static final $allTransitiveDependencies0 = playSubjectStateProvider;
  static final $allTransitiveDependencies1 =
      PlaySubjectStateProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$playContinueEpisodeHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return playContinueEpisode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$playContinueEpisodeHash() =>
    r'bea9e3d8435bc6af8334f821ab959ac955bd560c';

@ProviderFor(PlaySubjectState)
final playSubjectStateProvider = PlaySubjectStateProvider._();

final class PlaySubjectStateProvider
    extends $NotifierProvider<PlaySubjectState, PlaySubjectValue> {
  PlaySubjectStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playSubjectStateProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[playRouteExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            PlaySubjectStateProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = playRouteExtraProvider;

  @override
  String debugGetCreateSourceHash() => _$playSubjectStateHash();

  @$internal
  @override
  PlaySubjectState create() => PlaySubjectState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaySubjectValue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaySubjectValue>(value),
    );
  }
}

String _$playSubjectStateHash() => r'8c01bbe2dcf00d77be0fe8f58853e0f9c4c7eb71';

abstract class _$PlaySubjectState extends $Notifier<PlaySubjectValue> {
  PlaySubjectValue build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlaySubjectValue, PlaySubjectValue>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PlaySubjectValue, PlaySubjectValue>,
        PlaySubjectValue,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes_args.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(animeInfoArgs)
final animeInfoArgsProvider = AnimeInfoArgsProvider._();

final class AnimeInfoArgsProvider
    extends $FunctionalProvider<InfoRouteExtra, InfoRouteExtra, InfoRouteExtra>
    with $Provider<InfoRouteExtra> {
  AnimeInfoArgsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'animeInfoArgsProvider',
          isAutoDispose: false,
          dependencies: <ProviderOrFamily>[],
          $allTransitiveDependencies: <ProviderOrFamily>[],
        );

  @override
  String debugGetCreateSourceHash() => _$animeInfoArgsHash();

  @$internal
  @override
  $ProviderElement<InfoRouteExtra> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InfoRouteExtra create(Ref ref) {
    return animeInfoArgs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InfoRouteExtra value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InfoRouteExtra>(value),
    );
  }
}

String _$animeInfoArgsHash() => r'448ca6b6d5b60ca91a0462155df50eef78124585';

@ProviderFor(charactersArgs)
final charactersArgsProvider = CharactersArgsProvider._();

final class CharactersArgsProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  CharactersArgsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'charactersArgsProvider',
          isAutoDispose: false,
          dependencies: <ProviderOrFamily>[],
          $allTransitiveDependencies: <ProviderOrFamily>[],
        );

  @override
  String debugGetCreateSourceHash() => _$charactersArgsHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return charactersArgs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$charactersArgsHash() => r'2b5f66d7d59bcbe53c5446cda42efd2f2c48a3ec';

@ProviderFor(characterInfoArgs)
final characterInfoArgsProvider = CharacterInfoArgsProvider._();

final class CharacterInfoArgsProvider extends $FunctionalProvider<
    CharacterInfoExtra,
    CharacterInfoExtra,
    CharacterInfoExtra> with $Provider<CharacterInfoExtra> {
  CharacterInfoArgsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'characterInfoArgsProvider',
          isAutoDispose: false,
          dependencies: <ProviderOrFamily>[],
          $allTransitiveDependencies: <ProviderOrFamily>[],
        );

  @override
  String debugGetCreateSourceHash() => _$characterInfoArgsHash();

  @$internal
  @override
  $ProviderElement<CharacterInfoExtra> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CharacterInfoExtra create(Ref ref) {
    return characterInfoArgs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterInfoExtra value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterInfoExtra>(value),
    );
  }
}

String _$characterInfoArgsHash() => r'a8fabaf7e796f8ae188a45fc0d193ce0726ee709';

@ProviderFor(playExtra)
final playExtraProvider = PlayExtraProvider._();

final class PlayExtraProvider
    extends $FunctionalProvider<PlayRouteExtra, PlayRouteExtra, PlayRouteExtra>
    with $Provider<PlayRouteExtra> {
  PlayExtraProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playExtraProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[],
          $allTransitiveDependencies: <ProviderOrFamily>[],
        );

  @override
  String debugGetCreateSourceHash() => _$playExtraHash();

  @$internal
  @override
  $ProviderElement<PlayRouteExtra> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlayRouteExtra create(Ref ref) {
    return playExtra(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayRouteExtra value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayRouteExtra>(value),
    );
  }
}

String _$playExtraHash() => r'fdb488cc3eed729dc75faff4521ad0ce66f61c09';

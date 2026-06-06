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

String _$charactersArgsHash() => r'ea77d80c8e4387b58e15aa94ef94d2c0f59391a6';

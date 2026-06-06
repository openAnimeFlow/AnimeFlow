// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_info_args.dart';

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
          isAutoDispose: true,
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

String _$animeInfoArgsHash() => r'003e1179af7e8fc484f13a96aa2e470d9944e6a1';

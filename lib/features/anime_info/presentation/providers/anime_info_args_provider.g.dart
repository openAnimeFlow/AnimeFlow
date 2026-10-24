// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_info_args_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 由路由的 ProviderScope 提供页面参数。

@ProviderFor(animeInfoArgs)
final animeInfoArgsProvider = AnimeInfoArgsProvider._();

/// 由路由的 ProviderScope 提供页面参数。

final class AnimeInfoArgsProvider
    extends $FunctionalProvider<InfoRouteExtra, InfoRouteExtra, InfoRouteExtra>
    with $Provider<InfoRouteExtra> {
  /// 由路由的 ProviderScope 提供页面参数。
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_args_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 由路由的 ProviderScope 提供页面参数。

@ProviderFor(playExtra)
final playExtraProvider = PlayExtraProvider._();

/// 由路由的 ProviderScope 提供页面参数。

final class PlayExtraProvider
    extends $FunctionalProvider<PlayRouteExtra, PlayRouteExtra, PlayRouteExtra>
    with $Provider<PlayRouteExtra> {
  /// 由路由的 ProviderScope 提供页面参数。
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

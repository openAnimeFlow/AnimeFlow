// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_info_args_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 由路由的 ProviderScope 提供页面参数。

@ProviderFor(characterInfoArgs)
final characterInfoArgsProvider = CharacterInfoArgsProvider._();

/// 由路由的 ProviderScope 提供页面参数。

final class CharacterInfoArgsProvider extends $FunctionalProvider<
    CharacterInfoExtra,
    CharacterInfoExtra,
    CharacterInfoExtra> with $Provider<CharacterInfoExtra> {
  /// 由路由的 ProviderScope 提供页面参数。
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

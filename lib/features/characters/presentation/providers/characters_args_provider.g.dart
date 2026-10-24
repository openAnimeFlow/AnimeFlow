// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'characters_args_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 由路由的 ProviderScope 提供页面参数。

@ProviderFor(charactersArgs)
final charactersArgsProvider = CharactersArgsProvider._();

/// 由路由的 ProviderScope 提供页面参数。

final class CharactersArgsProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 由路由的 ProviderScope 提供页面参数。
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(flowTokenRepository)
final flowTokenRepositoryProvider = FlowTokenRepositoryProvider._();

final class FlowTokenRepositoryProvider extends $FunctionalProvider<
    TokenRepository<FlowToken>,
    TokenRepository<FlowToken>,
    TokenRepository<FlowToken>> with $Provider<TokenRepository<FlowToken>> {
  FlowTokenRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'flowTokenRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$flowTokenRepositoryHash();

  @$internal
  @override
  $ProviderElement<TokenRepository<FlowToken>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenRepository<FlowToken> create(Ref ref) {
    return flowTokenRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenRepository<FlowToken> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenRepository<FlowToken>>(value),
    );
  }
}

String _$flowTokenRepositoryHash() =>
    r'b693b8ce2bf80424f29ea5c2323d3ea8edb1fad5';

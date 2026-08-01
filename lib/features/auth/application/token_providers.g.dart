// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tokenRepository)
final tokenRepositoryProvider = TokenRepositoryProvider._();

final class TokenRepositoryProvider extends $FunctionalProvider<
    TokenRepository<TokenItem>,
    TokenRepository<TokenItem>,
    TokenRepository<TokenItem>> with $Provider<TokenRepository<TokenItem>> {
  TokenRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'tokenRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$tokenRepositoryHash();

  @$internal
  @override
  $ProviderElement<TokenRepository<TokenItem>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenRepository<TokenItem> create(Ref ref) {
    return tokenRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenRepository<TokenItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenRepository<TokenItem>>(value),
    );
  }
}

String _$tokenRepositoryHash() => r'30a91a5f9bf2dc17719a551f3cf0abb1762ebe2e';

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

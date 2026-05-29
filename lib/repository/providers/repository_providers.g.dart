// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tokenRepository)
final tokenRepositoryProvider = TokenRepositoryProvider._();

final class TokenRepositoryProvider extends $FunctionalProvider<TokenRepository,
    TokenRepository, TokenRepository> with $Provider<TokenRepository> {
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
  $ProviderElement<TokenRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenRepository create(Ref ref) {
    return tokenRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenRepository>(value),
    );
  }
}

String _$tokenRepositoryHash() => r'77e8a245e66fe85d263eb51d37cbf598911cde63';

@ProviderFor(userRepository)
final userRepositoryProvider = UserRepositoryProvider._();

final class UserRepositoryProvider
    extends $FunctionalProvider<UserRepository, UserRepository, UserRepository>
    with $Provider<UserRepository> {
  UserRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserRepository create(Ref ref) {
    return userRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserRepository>(value),
    );
  }
}

String _$userRepositoryHash() => r'84ebea9d77037ee3902cc442482e31c5897f287b';

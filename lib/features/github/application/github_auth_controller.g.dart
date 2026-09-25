// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gitHubAuthApi)
final gitHubAuthApiProvider = GitHubAuthApiProvider._();

final class GitHubAuthApiProvider
    extends $FunctionalProvider<GitHubAuthApi, GitHubAuthApi, GitHubAuthApi>
    with $Provider<GitHubAuthApi> {
  GitHubAuthApiProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'gitHubAuthApiProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$gitHubAuthApiHash();

  @$internal
  @override
  $ProviderElement<GitHubAuthApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GitHubAuthApi create(Ref ref) {
    return gitHubAuthApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitHubAuthApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitHubAuthApi>(value),
    );
  }
}

String _$gitHubAuthApiHash() => r'1f17735240731ddf561383029bf87d13aa6fce89';

@ProviderFor(gitHubTokenRepository)
final gitHubTokenRepositoryProvider = GitHubTokenRepositoryProvider._();

final class GitHubTokenRepositoryProvider extends $FunctionalProvider<
    TokenRepository<GitHubToken>,
    TokenRepository<GitHubToken>,
    TokenRepository<GitHubToken>> with $Provider<TokenRepository<GitHubToken>> {
  GitHubTokenRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'gitHubTokenRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$gitHubTokenRepositoryHash();

  @$internal
  @override
  $ProviderElement<TokenRepository<GitHubToken>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenRepository<GitHubToken> create(Ref ref) {
    return gitHubTokenRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenRepository<GitHubToken> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenRepository<GitHubToken>>(value),
    );
  }
}

String _$gitHubTokenRepositoryHash() =>
    r'70d999fcc2c3ae59363696edee476256a8755e1e';

@ProviderFor(GitHubAuthController)
final gitHubAuthControllerProvider = GitHubAuthControllerProvider._();

final class GitHubAuthControllerProvider
    extends $NotifierProvider<GitHubAuthController, GitHubAuthState> {
  GitHubAuthControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'gitHubAuthControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$gitHubAuthControllerHash();

  @$internal
  @override
  GitHubAuthController create() => GitHubAuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitHubAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitHubAuthState>(value),
    );
  }
}

String _$gitHubAuthControllerHash() =>
    r'17b1eade52c07a1f504934bd5e8fe0179c7431f2';

abstract class _$GitHubAuthController extends $Notifier<GitHubAuthState> {
  GitHubAuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GitHubAuthState, GitHubAuthState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<GitHubAuthState, GitHubAuthState>,
        GitHubAuthState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

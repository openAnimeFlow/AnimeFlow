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

String _$gitHubAuthApiHash() => r'93c33640e7ce3865bc685ad59bc26e0e16669289';

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

@ProviderFor(gitHubTokenManager)
final gitHubTokenManagerProvider = GitHubTokenManagerProvider._();

final class GitHubTokenManagerProvider extends $FunctionalProvider<
    GitHubTokenManager,
    GitHubTokenManager,
    GitHubTokenManager> with $Provider<GitHubTokenManager> {
  GitHubTokenManagerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'gitHubTokenManagerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$gitHubTokenManagerHash();

  @$internal
  @override
  $ProviderElement<GitHubTokenManager> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GitHubTokenManager create(Ref ref) {
    return gitHubTokenManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitHubTokenManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitHubTokenManager>(value),
    );
  }
}

String _$gitHubTokenManagerHash() =>
    r'c7542e0e13ba6fcfec13137afc918edf8ee5224b';

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
    r'd87ff58b979d798e1a68151a71b952d99b809c77';

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

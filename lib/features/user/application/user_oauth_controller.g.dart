// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_oauth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserOAuthController)
final userOAuthControllerProvider = UserOAuthControllerProvider._();

final class UserOAuthControllerProvider
    extends $NotifierProvider<UserOAuthController, UserOAuthState> {
  UserOAuthControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userOAuthControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userOAuthControllerHash();

  @$internal
  @override
  UserOAuthController create() => UserOAuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserOAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserOAuthState>(value),
    );
  }
}

String _$userOAuthControllerHash() =>
    r'b8033c00e418bcb9323927d1fe2ecb1bc1f6d230';

abstract class _$UserOAuthController extends $Notifier<UserOAuthState> {
  UserOAuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UserOAuthState, UserOAuthState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<UserOAuthState, UserOAuthState>,
        UserOAuthState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserController)
final userControllerProvider = UserControllerProvider._();

final class UserControllerProvider
    extends $NotifierProvider<UserController, UserOAuthState> {
  UserControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userControllerHash();

  @$internal
  @override
  UserController create() => UserController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserOAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserOAuthState>(value),
    );
  }
}

String _$userControllerHash() => r'0af6ccef258bc7e9e077d4cff32c8b9e7e036191';

abstract class _$UserController extends $Notifier<UserOAuthState> {
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

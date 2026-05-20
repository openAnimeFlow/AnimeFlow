// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentUserInfo)
final currentUserInfoProvider = CurrentUserInfoProvider._();

final class CurrentUserInfoProvider
    extends $NotifierProvider<CurrentUserInfo, UserInfoItem?> {
  CurrentUserInfoProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentUserInfoProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserInfoHash();

  @$internal
  @override
  CurrentUserInfo create() => CurrentUserInfo();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserInfoItem? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserInfoItem?>(value),
    );
  }
}

String _$currentUserInfoHash() => r'89c4d93ffe8f15977813a3e089da9fb24fef78fa';

abstract class _$CurrentUserInfo extends $Notifier<UserInfoItem?> {
  UserInfoItem? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UserInfoItem?, UserInfoItem?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<UserInfoItem?, UserInfoItem?>,
        UserInfoItem?,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(OAuthAuthorizing)
final oAuthAuthorizingProvider = OAuthAuthorizingProvider._();

final class OAuthAuthorizingProvider
    extends $NotifierProvider<OAuthAuthorizing, bool> {
  OAuthAuthorizingProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'oAuthAuthorizingProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$oAuthAuthorizingHash();

  @$internal
  @override
  OAuthAuthorizing create() => OAuthAuthorizing();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$oAuthAuthorizingHash() => r'b1b2ba5ffe05802b8d49c7e98df8f9c40c357903';

abstract class _$OAuthAuthorizing extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

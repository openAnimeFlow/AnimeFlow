// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentUserToken)
final currentUserTokenProvider = CurrentUserTokenProvider._();

final class CurrentUserTokenProvider
    extends $AsyncNotifierProvider<CurrentUserToken, TokenItem?> {
  CurrentUserTokenProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentUserTokenProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserTokenHash();

  @$internal
  @override
  CurrentUserToken create() => CurrentUserToken();
}

String _$currentUserTokenHash() => r'be21408f0cd645a61035bd085cbf85c19c5cc454';

abstract class _$CurrentUserToken extends $AsyncNotifier<TokenItem?> {
  FutureOr<TokenItem?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TokenItem?>, TokenItem?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<TokenItem?>, TokenItem?>,
        AsyncValue<TokenItem?>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(isLoggedIn)
final isLoggedInProvider = IsLoggedInProvider._();

final class IsLoggedInProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsLoggedInProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isLoggedInProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isLoggedInHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return isLoggedIn(ref);
  }
}

String _$isLoggedInHash() => r'6e63d4684fabb36ed92287e7ffec88ced998ee16';

@ProviderFor(CurrentUserInfo)
final currentUserInfoProvider = CurrentUserInfoProvider._();

final class CurrentUserInfoProvider
    extends $AsyncNotifierProvider<CurrentUserInfo, UserInfoItem?> {
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
}

String _$currentUserInfoHash() => r'6f716026aae9eac100a1fdc23bf728a4dc88d601';

abstract class _$CurrentUserInfo extends $AsyncNotifier<UserInfoItem?> {
  FutureOr<UserInfoItem?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserInfoItem?>, UserInfoItem?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<UserInfoItem?>, UserInfoItem?>,
        AsyncValue<UserInfoItem?>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

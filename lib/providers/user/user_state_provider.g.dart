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

@ProviderFor(CurrentFlowToken)
final currentFlowTokenProvider = CurrentFlowTokenProvider._();

final class CurrentFlowTokenProvider
    extends $AsyncNotifierProvider<CurrentFlowToken, FlowToken?> {
  CurrentFlowTokenProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentFlowTokenProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentFlowTokenHash();

  @$internal
  @override
  CurrentFlowToken create() => CurrentFlowToken();
}

String _$currentFlowTokenHash() => r'6344bd3d595a4693694b6e88efb5ee144a8a3fe0';

abstract class _$CurrentFlowToken extends $AsyncNotifier<FlowToken?> {
  FutureOr<FlowToken?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FlowToken?>, FlowToken?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<FlowToken?>, FlowToken?>,
        AsyncValue<FlowToken?>,
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

String _$isLoggedInHash() => r'34cdd0d8d6d6fb849bd0ab13e13c43188cd3c9dd';

@ProviderFor(bangumiBind)
final bangumiBindProvider = BangumiBindProvider._();

final class BangumiBindProvider extends $FunctionalProvider<
        AsyncValue<BangumiBindItem?>,
        BangumiBindItem?,
        FutureOr<BangumiBindItem?>>
    with $FutureModifier<BangumiBindItem?>, $FutureProvider<BangumiBindItem?> {
  BangumiBindProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'bangumiBindProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$bangumiBindHash();

  @$internal
  @override
  $FutureProviderElement<BangumiBindItem?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<BangumiBindItem?> create(Ref ref) {
    return bangumiBind(ref);
  }
}

String _$bangumiBindHash() => r'901f79109a6005eb777f90bc2a185bdd6da5d8f6';

@ProviderFor(CurrentUserInfo)
final currentUserInfoProvider = CurrentUserInfoProvider._();

final class CurrentUserInfoProvider
    extends $AsyncNotifierProvider<CurrentUserInfo, FlowUsers?> {
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

String _$currentUserInfoHash() => r'19bcd9107922323a08690dd0b9c4da6f377d3508';

abstract class _$CurrentUserInfo extends $AsyncNotifier<FlowUsers?> {
  FutureOr<FlowUsers?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FlowUsers?>, FlowUsers?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<FlowUsers?>, FlowUsers?>,
        AsyncValue<FlowUsers?>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前 AnimeFlow 账号操作控制器。

@ProviderFor(AccountController)
final accountControllerProvider = AccountControllerProvider._();

/// 当前 AnimeFlow 账号操作控制器。
final class AccountControllerProvider
    extends $NotifierProvider<AccountController, void> {
  /// 当前 AnimeFlow 账号操作控制器。
  AccountControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'accountControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$accountControllerHash();

  @$internal
  @override
  AccountController create() => AccountController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$accountControllerHash() => r'97e61a994dc81e4dcef46bd78f30806e60c7666f';

/// 当前 AnimeFlow 账号操作控制器。

abstract class _$AccountController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

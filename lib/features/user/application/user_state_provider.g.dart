// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$bangumiBindHash() => r'c30ea7f86670ed86c5b430ad4898c9d5cc248f40';

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

String _$currentUserInfoHash() => r'577c4d1d52cd42d43dbf25289aa7bf0dc3e75415';

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

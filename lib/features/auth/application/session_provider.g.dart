// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$currentFlowTokenHash() => r'fc38cf9009732885692155c42e1b2a0858fb0765';

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

String _$isLoggedInHash() => r'1cf9282f0e24558ef513e785654953d000e69181';

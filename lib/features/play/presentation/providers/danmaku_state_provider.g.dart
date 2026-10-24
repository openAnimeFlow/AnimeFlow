// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'danmaku_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DanmakuStateNotifier)
final danmakuStateProvider = DanmakuStateNotifierProvider._();

final class DanmakuStateNotifierProvider
    extends $NotifierProvider<DanmakuStateNotifier, DanmakuState> {
  DanmakuStateNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'danmakuStateProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[playExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            DanmakuStateNotifierProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = playExtraProvider;

  @override
  String debugGetCreateSourceHash() => _$danmakuStateNotifierHash();

  @$internal
  @override
  DanmakuStateNotifier create() => DanmakuStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DanmakuState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DanmakuState>(value),
    );
  }
}

String _$danmakuStateNotifierHash() =>
    r'6b53205e87ba3181fb2d684d20f0eafd09815547';

abstract class _$DanmakuStateNotifier extends $Notifier<DanmakuState> {
  DanmakuState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DanmakuState, DanmakuState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<DanmakuState, DanmakuState>,
        DanmakuState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

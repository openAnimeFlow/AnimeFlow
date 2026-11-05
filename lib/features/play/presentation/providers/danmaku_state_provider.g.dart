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
    r'14fff3157250bbb7f16eded408e3eff4fcba791d';

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

@ProviderFor(DanmakuChineseModeNotifier)
final danmakuChineseModeProvider = DanmakuChineseModeNotifierProvider._();

final class DanmakuChineseModeNotifierProvider
    extends $NotifierProvider<DanmakuChineseModeNotifier, DanmakuChineseMode> {
  DanmakuChineseModeNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'danmakuChineseModeProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$danmakuChineseModeNotifierHash();

  @$internal
  @override
  DanmakuChineseModeNotifier create() => DanmakuChineseModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DanmakuChineseMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DanmakuChineseMode>(value),
    );
  }
}

String _$danmakuChineseModeNotifierHash() =>
    r'ceae3504a434982f2f6aba6eab6ddc82de3ecc79';

abstract class _$DanmakuChineseModeNotifier
    extends $Notifier<DanmakuChineseMode> {
  DanmakuChineseMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DanmakuChineseMode, DanmakuChineseMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<DanmakuChineseMode, DanmakuChineseMode>,
        DanmakuChineseMode,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

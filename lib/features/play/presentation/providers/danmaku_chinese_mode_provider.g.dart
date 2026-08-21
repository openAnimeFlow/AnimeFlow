// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'danmaku_chinese_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
    r'deb27578aec653da7924968850267d3bf9043d69';

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

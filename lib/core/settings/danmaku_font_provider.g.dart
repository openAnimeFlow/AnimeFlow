// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'danmaku_font_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 弹幕专用字体。为空时跟随项目主题字体。

@ProviderFor(DanmakuFontFamily)
final danmakuFontFamilyProvider = DanmakuFontFamilyProvider._();

/// 弹幕专用字体。为空时跟随项目主题字体。
final class DanmakuFontFamilyProvider
    extends $NotifierProvider<DanmakuFontFamily, String?> {
  /// 弹幕专用字体。为空时跟随项目主题字体。
  DanmakuFontFamilyProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'danmakuFontFamilyProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$danmakuFontFamilyHash();

  @$internal
  @override
  DanmakuFontFamily create() => DanmakuFontFamily();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$danmakuFontFamilyHash() => r'57d6eac345329b4ef25e83d3fb53e2baa2bebe99';

/// 弹幕专用字体。为空时跟随项目主题字体。

abstract class _$DanmakuFontFamily extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<String?, String?>, String?, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

/// 是否在弹幕画布中应用项目或自定义字体。

@ProviderFor(DanmakuFontEnabled)
final danmakuFontEnabledProvider = DanmakuFontEnabledProvider._();

/// 是否在弹幕画布中应用项目或自定义字体。
final class DanmakuFontEnabledProvider
    extends $NotifierProvider<DanmakuFontEnabled, bool> {
  /// 是否在弹幕画布中应用项目或自定义字体。
  DanmakuFontEnabledProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'danmakuFontEnabledProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$danmakuFontEnabledHash();

  @$internal
  @override
  DanmakuFontEnabled create() => DanmakuFontEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$danmakuFontEnabledHash() =>
    r'02efaa7fcc5e613446b3a1bce9d88d024083e553';

/// 是否在弹幕画布中应用项目或自定义字体。

abstract class _$DanmakuFontEnabled extends $Notifier<bool> {
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

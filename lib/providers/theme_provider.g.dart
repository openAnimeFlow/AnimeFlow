// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局主题（保持存活，避免未监听时被 dispose）。

@ProviderFor(ThemeNotifier)
final themeProvider = ThemeNotifierProvider._();

/// 全局主题（保持存活，避免未监听时被 dispose）。
final class ThemeNotifierProvider
    extends $NotifierProvider<ThemeNotifier, ThemeState> {
  /// 全局主题（保持存活，避免未监听时被 dispose）。
  ThemeNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'themeProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$themeNotifierHash();

  @$internal
  @override
  ThemeNotifier create() => ThemeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeState>(value),
    );
  }
}

String _$themeNotifierHash() => r'6f450fcf7fc85a498b5c999d1fc589979637c455';

/// 全局主题（保持存活，避免未监听时被 dispose）。

abstract class _$ThemeNotifier extends $Notifier<ThemeState> {
  ThemeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeState, ThemeState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ThemeState, ThemeState>, ThemeState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

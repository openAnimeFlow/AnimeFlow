// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettingsLayout)
final settingsLayoutProvider = SettingsLayoutProvider._();

final class SettingsLayoutProvider
    extends $NotifierProvider<SettingsLayout, bool> {
  SettingsLayoutProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settingsLayoutProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$settingsLayoutHash();

  @$internal
  @override
  SettingsLayout create() => SettingsLayout();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$settingsLayoutHash() => r'b36421dedffff123b945522d7c58321e67773597';

abstract class _$SettingsLayout extends $Notifier<bool> {
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Scoped by the settings shell, including direct child-route navigation.

@ProviderFor(settingsLayout)
final settingsLayoutProvider = SettingsLayoutProvider._();

/// Scoped by the settings shell, including direct child-route navigation.

final class SettingsLayoutProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Scoped by the settings shell, including direct child-route navigation.
  SettingsLayoutProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'settingsLayoutProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[],
          $allTransitiveDependencies: <ProviderOrFamily>[],
        );

  @override
  String debugGetCreateSourceHash() => _$settingsLayoutHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return settingsLayout(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$settingsLayoutHash() => r'ac3ef280f2845a2a77e0655879f15ebef2b9f04e';

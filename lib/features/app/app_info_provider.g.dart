// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

final class AppVersionProvider
    extends $FunctionalProvider<String, String, String> with $Provider<String> {
  AppVersionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appVersionProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return appVersion(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$appVersionHash() => r'b09267ae01f15ed97510858967de95b800840cdc';

@ProviderFor(AppInfo)
final appInfoProvider = AppInfoProvider._();

final class AppInfoProvider extends $NotifierProvider<AppInfo, AppInfoState> {
  AppInfoProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appInfoProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appInfoHash();

  @$internal
  @override
  AppInfo create() => AppInfo();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppInfoState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppInfoState>(value),
    );
  }
}

String _$appInfoHash() => r'4a4f05bd5f8bce0083a0c893fb8918d98982a3df';

abstract class _$AppInfo extends $Notifier<AppInfoState> {
  AppInfoState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppInfoState, AppInfoState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AppInfoState, AppInfoState>,
        AppInfoState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

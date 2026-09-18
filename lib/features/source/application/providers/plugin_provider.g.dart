// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PluginCatalog)
final pluginCatalogProvider = PluginCatalogProvider._();

final class PluginCatalogProvider
    extends $AsyncNotifierProvider<PluginCatalog, List<PluginCatalogItem>> {
  PluginCatalogProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pluginCatalogProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pluginCatalogHash();

  @$internal
  @override
  PluginCatalog create() => PluginCatalog();
}

String _$pluginCatalogHash() => r'acb8f2d0b1b01a342bf754b10a7b6a0b8e578b78';

abstract class _$PluginCatalog extends $AsyncNotifier<List<PluginCatalogItem>> {
  FutureOr<List<PluginCatalogItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<List<PluginCatalogItem>>, List<PluginCatalogItem>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<PluginCatalogItem>>,
            List<PluginCatalogItem>>,
        AsyncValue<List<PluginCatalogItem>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

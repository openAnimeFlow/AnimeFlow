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

String _$pluginCatalogHash() => r'b4d448a19f434cf5704d6b958cf93add57f1c154';

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

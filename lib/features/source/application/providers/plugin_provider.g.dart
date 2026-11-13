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

String _$pluginCatalogHash() => r'06194d626c366811e6f3a63027ee04fecd69fa2f';

abstract class _$PluginCatalog extends $AsyncNotifier<List<PluginCatalogItem>> {
  FutureOr<List<PluginCatalogItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<List<PluginCatalogItem>>, List<PluginCatalogItem>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<PluginCatalogItem>>,
            List<PluginCatalogItem>>,
        AsyncValue<List<PluginCatalogItem>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

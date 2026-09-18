// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_configs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SourceConfigs)
final sourceConfigsProvider = SourceConfigsProvider._();

final class SourceConfigsProvider
    extends $AsyncNotifierProvider<SourceConfigs, List<CrawlConfigItem>> {
  SourceConfigsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sourceConfigsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sourceConfigsHash();

  @$internal
  @override
  SourceConfigs create() => SourceConfigs();
}

String _$sourceConfigsHash() => r'022c740073c03caa424152040ea4c158b381b892';

abstract class _$SourceConfigs extends $AsyncNotifier<List<CrawlConfigItem>> {
  FutureOr<List<CrawlConfigItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<List<CrawlConfigItem>>, List<CrawlConfigItem>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<CrawlConfigItem>>, List<CrawlConfigItem>>,
        AsyncValue<List<CrawlConfigItem>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

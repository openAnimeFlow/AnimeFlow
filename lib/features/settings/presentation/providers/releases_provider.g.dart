// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'releases_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 简单分页用例直接访问 API，刷新和离开页面时取消当前请求。

@ProviderFor(Releases)
final releasesProvider = ReleasesProvider._();

/// 简单分页用例直接访问 API，刷新和离开页面时取消当前请求。
final class ReleasesProvider
    extends $AsyncNotifierProvider<Releases, ReleasesState> {
  /// 简单分页用例直接访问 API，刷新和离开页面时取消当前请求。
  ReleasesProvider._()
      : super(
          from: null,
          argument: null,
          retry: _manualRetry,
          name: r'releasesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$releasesHash();

  @$internal
  @override
  Releases create() => Releases();
}

String _$releasesHash() => r'327d3c85d2c98934f3f070c00677152faa0deefa';

/// 简单分页用例直接访问 API，刷新和离开页面时取消当前请求。

abstract class _$Releases extends $AsyncNotifier<ReleasesState> {
  FutureOr<ReleasesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ReleasesState>, ReleasesState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<ReleasesState>, ReleasesState>,
        AsyncValue<ReleasesState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

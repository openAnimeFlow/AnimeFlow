// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episodes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放页剧集状态，生命周期与 [playRouteExtraProvider] 绑定。

@ProviderFor(Episodes)
final episodesProvider = EpisodesProvider._();

/// 播放页剧集状态，生命周期与 [playRouteExtraProvider] 绑定。
final class EpisodesProvider extends $NotifierProvider<Episodes, EpisodesData> {
  /// 播放页剧集状态，生命周期与 [playRouteExtraProvider] 绑定。
  EpisodesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'episodesProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[playRouteExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            EpisodesProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = playRouteExtraProvider;

  @override
  String debugGetCreateSourceHash() => _$episodesHash();

  @$internal
  @override
  Episodes create() => Episodes();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EpisodesData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EpisodesData>(value),
    );
  }
}

String _$episodesHash() => r'bf6b054cffb023532a75018108423c01c57764ad';

/// 播放页剧集状态，生命周期与 [playRouteExtraProvider] 绑定。

abstract class _$Episodes extends $Notifier<EpisodesData> {
  EpisodesData build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EpisodesData, EpisodesData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<EpisodesData, EpisodesData>,
        EpisodesData,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

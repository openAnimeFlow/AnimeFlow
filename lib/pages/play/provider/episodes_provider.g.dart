// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episodes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放页剧集状态，生命周期与 [playExtraProvider] 绑定。
/// 当路由参数变化（切换到不同番剧）时自动重新加载剧集。

@ProviderFor(Episodes)
final episodesProvider = EpisodesProvider._();

/// 播放页剧集状态，生命周期与 [playExtraProvider] 绑定。
/// 当路由参数变化（切换到不同番剧）时自动重新加载剧集。
final class EpisodesProvider extends $NotifierProvider<Episodes, EpisodesData> {
  /// 播放页剧集状态，生命周期与 [playExtraProvider] 绑定。
  /// 当路由参数变化（切换到不同番剧）时自动重新加载剧集。
  EpisodesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'episodesProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[playExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            EpisodesProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = playExtraProvider;

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

String _$episodesHash() => r'092006556ecb8b3f95277b355008aba5e14158c9';

/// 播放页剧集状态，生命周期与 [playExtraProvider] 绑定。
/// 当路由参数变化（切换到不同番剧）时自动重新加载剧集。

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

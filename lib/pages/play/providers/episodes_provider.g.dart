// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episodes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当路由参数变化（切换到不同番剧）时自动重新加载剧集。

@ProviderFor(Episodes)
final episodesProvider = EpisodesProvider._();

/// 当路由参数变化（切换到不同番剧）时自动重新加载剧集。
final class EpisodesProvider
    extends $AsyncNotifierProvider<Episodes, EpisodesData> {
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
}

String _$episodesHash() => r'077f6a49dcfedddf95885587a96f3b3ba419acf1';

/// 当路由参数变化（切换到不同番剧）时自动重新加载剧集。

abstract class _$Episodes extends $AsyncNotifier<EpisodesData> {
  FutureOr<EpisodesData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EpisodesData>, EpisodesData>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<EpisodesData>, EpisodesData>,
        AsyncValue<EpisodesData>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

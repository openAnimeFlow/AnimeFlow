// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episodes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Episodes)
final episodesProvider = EpisodesProvider._();

final class EpisodesProvider
    extends $AsyncNotifierProvider<Episodes, EpisodesData> {
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

String _$episodesHash() => r'cd6c01f10ad5f51814fc803acb59b7aedcbf3e08';

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

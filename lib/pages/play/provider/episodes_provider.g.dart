// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episodes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Episodes)
final episodesProvider = EpisodesProvider._();

final class EpisodesProvider extends $NotifierProvider<Episodes, EpisodesData> {
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

String _$episodesHash() => r'0e33435f92a70978f38af40308f535688641bcba';

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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnimeHot)
final animeHotProvider = AnimeHotProvider._();

final class AnimeHotProvider
    extends $AsyncNotifierProvider<AnimeHot, AnimeHotState> {
  AnimeHotProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'animeHotProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$animeHotHash();

  @$internal
  @override
  AnimeHot create() => AnimeHot();
}

String _$animeHotHash() => r'e47bfbd49b088563b29e0bf46d582160971b4d9c';

abstract class _$AnimeHot extends $AsyncNotifier<AnimeHotState> {
  FutureOr<AnimeHotState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AnimeHotState>, AnimeHotState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AnimeHotState>, AnimeHotState>,
        AsyncValue<AnimeHotState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

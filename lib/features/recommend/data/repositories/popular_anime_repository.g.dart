// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'popular_anime_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PopularAnimeRepository)
final popularAnimeRepositoryProvider = PopularAnimeRepositoryProvider._();

final class PopularAnimeRepositoryProvider
    extends $NotifierProvider<PopularAnimeRepository, void> {
  PopularAnimeRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'popularAnimeRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$popularAnimeRepositoryHash();

  @$internal
  @override
  PopularAnimeRepository create() => PopularAnimeRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$popularAnimeRepositoryHash() =>
    r'c7f2ee8286a970634d7bd51da3c1cecfd29fad0c';

abstract class _$PopularAnimeRepository extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

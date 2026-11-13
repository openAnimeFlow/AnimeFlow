// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_info_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnimeInfoRepository)
final animeInfoRepositoryProvider = AnimeInfoRepositoryProvider._();

final class AnimeInfoRepositoryProvider
    extends $NotifierProvider<AnimeInfoRepository, void> {
  AnimeInfoRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'animeInfoRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$animeInfoRepositoryHash();

  @$internal
  @override
  AnimeInfoRepository create() => AnimeInfoRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$animeInfoRepositoryHash() =>
    r'05b4a491cd8879685ccfae3219cc1a0a8b7163d5';

abstract class _$AnimeInfoRepository extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

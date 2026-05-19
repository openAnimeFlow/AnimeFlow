// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnimeCalendar)
final animeCalendarProvider = AnimeCalendarProvider._();

final class AnimeCalendarProvider
    extends $AsyncNotifierProvider<AnimeCalendar, Calendar> {
  AnimeCalendarProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'animeCalendarProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$animeCalendarHash();

  @$internal
  @override
  AnimeCalendar create() => AnimeCalendar();
}

String _$animeCalendarHash() => r'867e327439951ba3473964c40fdd355f173d90eb';

abstract class _$AnimeCalendar extends $AsyncNotifier<Calendar> {
  FutureOr<Calendar> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Calendar>, Calendar>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Calendar>, Calendar>,
        AsyncValue<Calendar>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

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

String _$animeHotHash() => r'5ad646c80e0953d18e4efc034a9bd99d36316ae4';

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

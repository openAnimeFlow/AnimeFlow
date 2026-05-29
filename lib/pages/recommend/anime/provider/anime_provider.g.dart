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

String _$animeCalendarHash() => r'2f6e10ae2213058b9e9f4a16dee7cc82208e4d31';

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

String _$animeHotHash() => r'd88acfbe9a5fbcc5e50eb9a14ffbd4138c342a57';

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

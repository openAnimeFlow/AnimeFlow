// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnimeInfo)
final animeInfoProvider = AnimeInfoFamily._();

final class AnimeInfoProvider
    extends $AsyncNotifierProvider<AnimeInfo, SubjectsInfoItem?> {
  AnimeInfoProvider._(
      {required AnimeInfoFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'animeInfoProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$animeInfoHash();

  @override
  String toString() {
    return r'animeInfoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AnimeInfo create() => AnimeInfo();

  @override
  bool operator ==(Object other) {
    return other is AnimeInfoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$animeInfoHash() => r'ddd36370a95b2cf40ed6175de72aa7ca62e6feda';

final class AnimeInfoFamily extends $Family
    with
        $ClassFamilyOverride<AnimeInfo, AsyncValue<SubjectsInfoItem?>,
            SubjectsInfoItem?, FutureOr<SubjectsInfoItem?>, int> {
  AnimeInfoFamily._()
      : super(
          retry: null,
          name: r'animeInfoProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  AnimeInfoProvider call(
    int subjectId,
  ) =>
      AnimeInfoProvider._(argument: subjectId, from: this);

  @override
  String toString() => r'animeInfoProvider';
}

abstract class _$AnimeInfo extends $AsyncNotifier<SubjectsInfoItem?> {
  late final _$args = ref.$arg as int;
  int get subjectId => _$args;

  FutureOr<SubjectsInfoItem?> build(
    int subjectId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SubjectsInfoItem?>, SubjectsInfoItem?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SubjectsInfoItem?>, SubjectsInfoItem?>,
        AsyncValue<SubjectsInfoItem?>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

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
    extends $AsyncNotifierProvider<AnimeInfo, AnimeInfoState> {
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

String _$animeInfoHash() => r'82998039a042b3a27e675e4a852a6cebcafc16f3';

final class AnimeInfoFamily extends $Family
    with
        $ClassFamilyOverride<AnimeInfo, AsyncValue<AnimeInfoState>,
            AnimeInfoState, FutureOr<AnimeInfoState>, int> {
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

abstract class _$AnimeInfo extends $AsyncNotifier<AnimeInfoState> {
  late final _$args = ref.$arg as int;
  int get subjectId => _$args;

  FutureOr<AnimeInfoState> build(
    int subjectId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AnimeInfoState>, AnimeInfoState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AnimeInfoState>, AnimeInfoState>,
        AsyncValue<AnimeInfoState>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

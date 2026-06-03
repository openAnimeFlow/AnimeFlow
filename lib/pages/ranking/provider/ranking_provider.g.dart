// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rankingYears)
final rankingYearsProvider = RankingYearsProvider._();

final class RankingYearsProvider
    extends $FunctionalProvider<List<int>, List<int>, List<int>>
    with $Provider<List<int>> {
  RankingYearsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'rankingYearsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$rankingYearsHash();

  @$internal
  @override
  $ProviderElement<List<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<int> create(Ref ref) {
    return rankingYears(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<int>>(value),
    );
  }
}

String _$rankingYearsHash() => r'ae464838384045d4fad25acb5f985d1f68d85207';

@ProviderFor(rankingMonths)
final rankingMonthsProvider = RankingMonthsProvider._();

final class RankingMonthsProvider
    extends $FunctionalProvider<List<int>, List<int>, List<int>>
    with $Provider<List<int>> {
  RankingMonthsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'rankingMonthsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$rankingMonthsHash();

  @$internal
  @override
  $ProviderElement<List<int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<int> create(Ref ref) {
    return rankingMonths(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<int>>(value),
    );
  }
}

String _$rankingMonthsHash() => r'eef507f9f7584fcfc5f58dce358675765fedd2d6';

@ProviderFor(Ranking)
final rankingProvider = RankingProvider._();

final class RankingProvider
    extends $AsyncNotifierProvider<Ranking, RankingState> {
  RankingProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'rankingProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$rankingHash();

  @$internal
  @override
  Ranking create() => Ranking();
}

String _$rankingHash() => r'499227533131578130f6ea697cd6e9a4911f6215';

abstract class _$Ranking extends $AsyncNotifier<RankingState> {
  FutureOr<RankingState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RankingState>, RankingState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<RankingState>, RankingState>,
        AsyncValue<RankingState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

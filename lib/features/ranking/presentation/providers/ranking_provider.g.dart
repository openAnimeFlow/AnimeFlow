// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$rankingHash() => r'1a2b6d8d84c5cd1559cf692074e737d16a600f86';

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

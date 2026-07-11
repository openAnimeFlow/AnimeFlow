// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_episodes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SubjectEpisodes)
final subjectEpisodesProvider = SubjectEpisodesFamily._();

final class SubjectEpisodesProvider
    extends $AsyncNotifierProvider<SubjectEpisodes, SubjectEpisodesState> {
  SubjectEpisodesProvider._(
      {required SubjectEpisodesFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'subjectEpisodesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$subjectEpisodesHash();

  @override
  String toString() {
    return r'subjectEpisodesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SubjectEpisodes create() => SubjectEpisodes();

  @override
  bool operator ==(Object other) {
    return other is SubjectEpisodesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subjectEpisodesHash() => r'f2df05b425121088a0edba67364c42287a391f1c';

final class SubjectEpisodesFamily extends $Family
    with
        $ClassFamilyOverride<SubjectEpisodes, AsyncValue<SubjectEpisodesState>,
            SubjectEpisodesState, FutureOr<SubjectEpisodesState>, int> {
  SubjectEpisodesFamily._()
      : super(
          retry: null,
          name: r'subjectEpisodesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SubjectEpisodesProvider call(
    int subjectId,
  ) =>
      SubjectEpisodesProvider._(argument: subjectId, from: this);

  @override
  String toString() => r'subjectEpisodesProvider';
}

abstract class _$SubjectEpisodes extends $AsyncNotifier<SubjectEpisodesState> {
  late final _$args = ref.$arg as int;
  int get subjectId => _$args;

  FutureOr<SubjectEpisodesState> build(
    int subjectId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<SubjectEpisodesState>, SubjectEpisodesState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SubjectEpisodesState>, SubjectEpisodesState>,
        AsyncValue<SubjectEpisodesState>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

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
    extends $AsyncNotifierProvider<AnimeInfo, SubjectsInfoItem> {
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

String _$animeInfoHash() => r'df40e4a2d487a4e8145b92996a037aab97eba092';

final class AnimeInfoFamily extends $Family
    with
        $ClassFamilyOverride<AnimeInfo, AsyncValue<SubjectsInfoItem>,
            SubjectsInfoItem, FutureOr<SubjectsInfoItem>, int> {
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

abstract class _$AnimeInfo extends $AsyncNotifier<SubjectsInfoItem> {
  late final _$args = ref.$arg as int;
  int get subjectId => _$args;

  FutureOr<SubjectsInfoItem> build(
    int subjectId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SubjectsInfoItem>, SubjectsInfoItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SubjectsInfoItem>, SubjectsInfoItem>,
        AsyncValue<SubjectsInfoItem>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

@ProviderFor(SubjectComments)
final subjectCommentsProvider = SubjectCommentsFamily._();

final class SubjectCommentsProvider
    extends $AsyncNotifierProvider<SubjectComments, SubjectCommentsViewState> {
  SubjectCommentsProvider._(
      {required SubjectCommentsFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'subjectCommentsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$subjectCommentsHash();

  @override
  String toString() {
    return r'subjectCommentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SubjectComments create() => SubjectComments();

  @override
  bool operator ==(Object other) {
    return other is SubjectCommentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subjectCommentsHash() => r'e9023fe12b86201a0b7b9120888500bed0ac8803';

final class SubjectCommentsFamily extends $Family
    with
        $ClassFamilyOverride<
            SubjectComments,
            AsyncValue<SubjectCommentsViewState>,
            SubjectCommentsViewState,
            FutureOr<SubjectCommentsViewState>,
            int> {
  SubjectCommentsFamily._()
      : super(
          retry: null,
          name: r'subjectCommentsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SubjectCommentsProvider call(
    int subjectId,
  ) =>
      SubjectCommentsProvider._(argument: subjectId, from: this);

  @override
  String toString() => r'subjectCommentsProvider';
}

abstract class _$SubjectComments
    extends $AsyncNotifier<SubjectCommentsViewState> {
  late final _$args = ref.$arg as int;
  int get subjectId => _$args;

  FutureOr<SubjectCommentsViewState> build(
    int subjectId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<SubjectCommentsViewState>, SubjectCommentsViewState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SubjectCommentsViewState>,
            SubjectCommentsViewState>,
        AsyncValue<SubjectCommentsViewState>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

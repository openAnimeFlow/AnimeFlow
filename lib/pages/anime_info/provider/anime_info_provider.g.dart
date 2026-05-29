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

String _$animeInfoHash() => r'065adc692dcd48f95b0da41d6a5d840653c51d42';

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

///相关条目

@ProviderFor(SubjectRelated)
final subjectRelatedProvider = SubjectRelatedFamily._();

///相关条目
final class SubjectRelatedProvider
    extends $AsyncNotifierProvider<SubjectRelated, SubjectRelationItem> {
  ///相关条目
  SubjectRelatedProvider._(
      {required SubjectRelatedFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'subjectRelatedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$subjectRelatedHash();

  @override
  String toString() {
    return r'subjectRelatedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SubjectRelated create() => SubjectRelated();

  @override
  bool operator ==(Object other) {
    return other is SubjectRelatedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subjectRelatedHash() => r'3afb97bc5bab2958b128418edcb3823c2a497ce6';

///相关条目

final class SubjectRelatedFamily extends $Family
    with
        $ClassFamilyOverride<SubjectRelated, AsyncValue<SubjectRelationItem>,
            SubjectRelationItem, FutureOr<SubjectRelationItem>, int> {
  SubjectRelatedFamily._()
      : super(
          retry: null,
          name: r'subjectRelatedProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ///相关条目

  SubjectRelatedProvider call(
    int subjectId,
  ) =>
      SubjectRelatedProvider._(argument: subjectId, from: this);

  @override
  String toString() => r'subjectRelatedProvider';
}

///相关条目

abstract class _$SubjectRelated extends $AsyncNotifier<SubjectRelationItem> {
  late final _$args = ref.$arg as int;
  int get subjectId => _$args;

  FutureOr<SubjectRelationItem> build(
    int subjectId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SubjectRelationItem>, SubjectRelationItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SubjectRelationItem>, SubjectRelationItem>,
        AsyncValue<SubjectRelationItem>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

///条目角色信息

@ProviderFor(SubjectCharacters)
final subjectCharactersProvider = SubjectCharactersFamily._();

///条目角色信息
final class SubjectCharactersProvider
    extends $AsyncNotifierProvider<SubjectCharacters, CharactersItem> {
  ///条目角色信息
  SubjectCharactersProvider._(
      {required SubjectCharactersFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'subjectCharactersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$subjectCharactersHash();

  @override
  String toString() {
    return r'subjectCharactersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SubjectCharacters create() => SubjectCharacters();

  @override
  bool operator ==(Object other) {
    return other is SubjectCharactersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subjectCharactersHash() => r'1879f27401bda7e37ca17ce4e90f5c6892f2b748';

///条目角色信息

final class SubjectCharactersFamily extends $Family
    with
        $ClassFamilyOverride<SubjectCharacters, AsyncValue<CharactersItem>,
            CharactersItem, FutureOr<CharactersItem>, int> {
  SubjectCharactersFamily._()
      : super(
          retry: null,
          name: r'subjectCharactersProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ///条目角色信息

  SubjectCharactersProvider call(
    int subjectId,
  ) =>
      SubjectCharactersProvider._(argument: subjectId, from: this);

  @override
  String toString() => r'subjectCharactersProvider';
}

///条目角色信息

abstract class _$SubjectCharacters extends $AsyncNotifier<CharactersItem> {
  late final _$args = ref.$arg as int;
  int get subjectId => _$args;

  FutureOr<CharactersItem> build(
    int subjectId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CharactersItem>, CharactersItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<CharactersItem>, CharactersItem>,
        AsyncValue<CharactersItem>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

///番剧制作人信息

@ProviderFor(SubjectProducers)
final subjectProducersProvider = SubjectProducersFamily._();

///番剧制作人信息
final class SubjectProducersProvider
    extends $AsyncNotifierProvider<SubjectProducers, ProducersItem> {
  ///番剧制作人信息
  SubjectProducersProvider._(
      {required SubjectProducersFamily super.from, required int super.argument})
      : super(
          retry: null,
          name: r'subjectProducersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$subjectProducersHash();

  @override
  String toString() {
    return r'subjectProducersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SubjectProducers create() => SubjectProducers();

  @override
  bool operator ==(Object other) {
    return other is SubjectProducersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subjectProducersHash() => r'00d63b907db7b0c56a8c6b3183b1afc67f913c5f';

///番剧制作人信息

final class SubjectProducersFamily extends $Family
    with
        $ClassFamilyOverride<SubjectProducers, AsyncValue<ProducersItem>,
            ProducersItem, FutureOr<ProducersItem>, int> {
  SubjectProducersFamily._()
      : super(
          retry: null,
          name: r'subjectProducersProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  ///番剧制作人信息

  SubjectProducersProvider call(
    int subjectId,
  ) =>
      SubjectProducersProvider._(argument: subjectId, from: this);

  @override
  String toString() => r'subjectProducersProvider';
}

///番剧制作人信息

abstract class _$SubjectProducers extends $AsyncNotifier<ProducersItem> {
  late final _$args = ref.$arg as int;
  int get subjectId => _$args;

  FutureOr<ProducersItem> build(
    int subjectId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ProducersItem>, ProducersItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<ProducersItem>, ProducersItem>,
        AsyncValue<ProducersItem>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

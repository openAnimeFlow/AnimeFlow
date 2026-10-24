// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_episodes_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 按会话保存剧集分页，避免不同账号的观看状态相互覆盖。

@ProviderFor(SubjectEpisodesRepository)
final subjectEpisodesRepositoryProvider = SubjectEpisodesRepositoryProvider._();

/// 按会话保存剧集分页，避免不同账号的观看状态相互覆盖。
final class SubjectEpisodesRepositoryProvider
    extends $NotifierProvider<SubjectEpisodesRepository, void> {
  /// 按会话保存剧集分页，避免不同账号的观看状态相互覆盖。
  SubjectEpisodesRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'subjectEpisodesRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$subjectEpisodesRepositoryHash();

  @$internal
  @override
  SubjectEpisodesRepository create() => SubjectEpisodesRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$subjectEpisodesRepositoryHash() =>
    r'81ad0b7996ce1ff4d455110ad84401ff96593fc2';

/// 按会话保存剧集分页，避免不同账号的观看状态相互覆盖。

abstract class _$SubjectEpisodesRepository extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

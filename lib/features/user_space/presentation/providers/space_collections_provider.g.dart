// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_collections_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 每个用户独立保存各标签的分页状态；切换标签不会覆盖另一个标签的响应。

@ProviderFor(SpaceCollections)
final spaceCollectionsProvider = SpaceCollectionsFamily._();

/// 每个用户独立保存各标签的分页状态；切换标签不会覆盖另一个标签的响应。
final class SpaceCollectionsProvider extends $NotifierProvider<SpaceCollections,
    Map<int, SpaceCollectionTabState>> {
  /// 每个用户独立保存各标签的分页状态；切换标签不会覆盖另一个标签的响应。
  SpaceCollectionsProvider._(
      {required SpaceCollectionsFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'spaceCollectionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$spaceCollectionsHash();

  @override
  String toString() {
    return r'spaceCollectionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SpaceCollections create() => SpaceCollections();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<int, SpaceCollectionTabState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<int, SpaceCollectionTabState>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpaceCollectionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$spaceCollectionsHash() => r'cd0065a03f1a6c4a8331a3e3d95ddaed14e8a9e6';

/// 每个用户独立保存各标签的分页状态；切换标签不会覆盖另一个标签的响应。

final class SpaceCollectionsFamily extends $Family
    with
        $ClassFamilyOverride<
            SpaceCollections,
            Map<int, SpaceCollectionTabState>,
            Map<int, SpaceCollectionTabState>,
            Map<int, SpaceCollectionTabState>,
            String> {
  SpaceCollectionsFamily._()
      : super(
          retry: null,
          name: r'spaceCollectionsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 每个用户独立保存各标签的分页状态；切换标签不会覆盖另一个标签的响应。

  SpaceCollectionsProvider call(
    String username,
  ) =>
      SpaceCollectionsProvider._(argument: username, from: this);

  @override
  String toString() => r'spaceCollectionsProvider';
}

/// 每个用户独立保存各标签的分页状态；切换标签不会覆盖另一个标签的响应。

abstract class _$SpaceCollections
    extends $Notifier<Map<int, SpaceCollectionTabState>> {
  late final _$args = ref.$arg as String;
  String get username => _$args;

  Map<int, SpaceCollectionTabState> build(
    String username,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<int, SpaceCollectionTabState>,
        Map<int, SpaceCollectionTabState>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<Map<int, SpaceCollectionTabState>,
            Map<int, SpaceCollectionTabState>>,
        Map<int, SpaceCollectionTabState>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

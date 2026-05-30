// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_space_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserSpace)
final userSpaceProvider = UserSpaceFamily._();

final class UserSpaceProvider
    extends $AsyncNotifierProvider<UserSpace, UserInfoItem> {
  UserSpaceProvider._(
      {required UserSpaceFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'userSpaceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userSpaceHash();

  @override
  String toString() {
    return r'userSpaceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserSpace create() => UserSpace();

  @override
  bool operator ==(Object other) {
    return other is UserSpaceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userSpaceHash() => r'600ad926a674acc31302b568d3f5ae4be9bc8362';

final class UserSpaceFamily extends $Family
    with
        $ClassFamilyOverride<UserSpace, AsyncValue<UserInfoItem>, UserInfoItem,
            FutureOr<UserInfoItem>, String> {
  UserSpaceFamily._()
      : super(
          retry: null,
          name: r'userSpaceProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  UserSpaceProvider call(
    String username,
  ) =>
      UserSpaceProvider._(argument: username, from: this);

  @override
  String toString() => r'userSpaceProvider';
}

abstract class _$UserSpace extends $AsyncNotifier<UserInfoItem> {
  late final _$args = ref.$arg as String;
  String get username => _$args;

  FutureOr<UserInfoItem> build(
    String username,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserInfoItem>, UserInfoItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<UserInfoItem>, UserInfoItem>,
        AsyncValue<UserInfoItem>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

@ProviderFor(UserSpaceStatistics)
final userSpaceStatisticsProvider = UserSpaceStatisticsFamily._();

final class UserSpaceStatisticsProvider
    extends $AsyncNotifierProvider<UserSpaceStatistics, BgmUserStatisticsItem> {
  UserSpaceStatisticsProvider._(
      {required UserSpaceStatisticsFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'userSpaceStatisticsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userSpaceStatisticsHash();

  @override
  String toString() {
    return r'userSpaceStatisticsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserSpaceStatistics create() => UserSpaceStatistics();

  @override
  bool operator ==(Object other) {
    return other is UserSpaceStatisticsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userSpaceStatisticsHash() =>
    r'a920b37d1703fa4740fae43aa1fe3ca6df5ac8de';

final class UserSpaceStatisticsFamily extends $Family
    with
        $ClassFamilyOverride<
            UserSpaceStatistics,
            AsyncValue<BgmUserStatisticsItem>,
            BgmUserStatisticsItem,
            FutureOr<BgmUserStatisticsItem>,
            String> {
  UserSpaceStatisticsFamily._()
      : super(
          retry: null,
          name: r'userSpaceStatisticsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  UserSpaceStatisticsProvider call(
    String username,
  ) =>
      UserSpaceStatisticsProvider._(argument: username, from: this);

  @override
  String toString() => r'userSpaceStatisticsProvider';
}

abstract class _$UserSpaceStatistics
    extends $AsyncNotifier<BgmUserStatisticsItem> {
  late final _$args = ref.$arg as String;
  String get username => _$args;

  FutureOr<BgmUserStatisticsItem> build(
    String username,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<BgmUserStatisticsItem>, BgmUserStatisticsItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<BgmUserStatisticsItem>, BgmUserStatisticsItem>,
        AsyncValue<BgmUserStatisticsItem>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

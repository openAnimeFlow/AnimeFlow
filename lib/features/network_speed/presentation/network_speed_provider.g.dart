// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_speed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 用于依赖注入：每次调用都创建一个独立实例。

@ProviderFor(networkSpeedServiceFactory)
final networkSpeedServiceFactoryProvider =
    NetworkSpeedServiceFactoryProvider._();

/// 用于依赖注入：每次调用都创建一个独立实例。

final class NetworkSpeedServiceFactoryProvider extends $FunctionalProvider<
        NetworkSpeedService Function(),
        NetworkSpeedService Function(),
        NetworkSpeedService Function()>
    with $Provider<NetworkSpeedService Function()> {
  /// 用于依赖注入：每次调用都创建一个独立实例。
  NetworkSpeedServiceFactoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'networkSpeedServiceFactoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$networkSpeedServiceFactoryHash();

  @$internal
  @override
  $ProviderElement<NetworkSpeedService Function()> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NetworkSpeedService Function() create(Ref ref) {
    return networkSpeedServiceFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkSpeedService Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<NetworkSpeedService Function()>(value),
    );
  }
}

String _$networkSpeedServiceFactoryHash() =>
    r'df8dc538b1088d32710a806a0bb1ed12ff135a54';

/// Riverpod 托管 start/stop 生命周期。
/// - 首次 watch 时自动 start
/// - autoDispose 时自动 stop

@ProviderFor(networkSpeedStream)
final networkSpeedStreamProvider = NetworkSpeedStreamFamily._();

/// Riverpod 托管 start/stop 生命周期。
/// - 首次 watch 时自动 start
/// - autoDispose 时自动 stop

final class NetworkSpeedStreamProvider extends $FunctionalProvider<
        AsyncValue<NetworkSpeed>, NetworkSpeed, Stream<NetworkSpeed>>
    with $FutureModifier<NetworkSpeed>, $StreamProvider<NetworkSpeed> {
  /// Riverpod 托管 start/stop 生命周期。
  /// - 首次 watch 时自动 start
  /// - autoDispose 时自动 stop
  NetworkSpeedStreamProvider._(
      {required NetworkSpeedStreamFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'networkSpeedStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$networkSpeedStreamHash();

  @override
  String toString() {
    return r'networkSpeedStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<NetworkSpeed> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<NetworkSpeed> create(Ref ref) {
    final argument = this.argument as int;
    return networkSpeedStream(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NetworkSpeedStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$networkSpeedStreamHash() =>
    r'78a4afd1773281b095fd6cd2b986ff2ca98f4ca4';

/// Riverpod 托管 start/stop 生命周期。
/// - 首次 watch 时自动 start
/// - autoDispose 时自动 stop

final class NetworkSpeedStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<NetworkSpeed>, int> {
  NetworkSpeedStreamFamily._()
      : super(
          retry: null,
          name: r'networkSpeedStreamProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Riverpod 托管 start/stop 生命周期。
  /// - 首次 watch 时自动 start
  /// - autoDispose 时自动 stop

  NetworkSpeedStreamProvider call(
    int intervalMs,
  ) =>
      NetworkSpeedStreamProvider._(argument: intervalMs, from: this);

  @override
  String toString() => r'networkSpeedStreamProvider';
}

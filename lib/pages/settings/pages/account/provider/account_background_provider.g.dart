// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_background_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 背景图列表。

@ProviderFor(backgroundImageList)
final backgroundImageListProvider = BackgroundImageListProvider._();

/// 背景图列表。

final class BackgroundImageListProvider extends $FunctionalProvider<
        AsyncValue<List<BackgroundImageItem>>,
        List<BackgroundImageItem>,
        FutureOr<List<BackgroundImageItem>>>
    with
        $FutureModifier<List<BackgroundImageItem>>,
        $FutureProvider<List<BackgroundImageItem>> {
  /// 背景图列表。
  BackgroundImageListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'backgroundImageListProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$backgroundImageListHash();

  @$internal
  @override
  $FutureProviderElement<List<BackgroundImageItem>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<BackgroundImageItem>> create(Ref ref) {
    return backgroundImageList(ref);
  }
}

String _$backgroundImageListHash() =>
    r'ed3b1c2301b9093f7a141177319a4caba9482bfa';

/// 当前用户已选背景图 ID

@ProviderFor(currentUserBackgroundId)
final currentUserBackgroundIdProvider = CurrentUserBackgroundIdProvider._();

/// 当前用户已选背景图 ID

final class CurrentUserBackgroundIdProvider
    extends $FunctionalProvider<int?, int?, int?> with $Provider<int?> {
  /// 当前用户已选背景图 ID
  CurrentUserBackgroundIdProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentUserBackgroundIdProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserBackgroundIdHash();

  @$internal
  @override
  $ProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int? create(Ref ref) {
    return currentUserBackgroundId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$currentUserBackgroundIdHash() =>
    r'f5974b5b8c1922dc7dacfeaca25f0418a5c3c345';

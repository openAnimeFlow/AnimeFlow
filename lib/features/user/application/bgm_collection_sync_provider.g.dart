// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bgm_collection_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BgmCollectionSync)
final bgmCollectionSyncProvider = BgmCollectionSyncProvider._();

final class BgmCollectionSyncProvider extends $AsyncNotifierProvider<
    BgmCollectionSync, BgmCollectionSyncStatusItem?> {
  BgmCollectionSyncProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'bgmCollectionSyncProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$bgmCollectionSyncHash();

  @$internal
  @override
  BgmCollectionSync create() => BgmCollectionSync();
}

String _$bgmCollectionSyncHash() => r'bce50f303325199bf651fc89ac93b865b225d8c1';

abstract class _$BgmCollectionSync
    extends $AsyncNotifier<BgmCollectionSyncStatusItem?> {
  FutureOr<BgmCollectionSyncStatusItem?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BgmCollectionSyncStatusItem?>,
        BgmCollectionSyncStatusItem?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<BgmCollectionSyncStatusItem?>,
            BgmCollectionSyncStatusItem?>,
        AsyncValue<BgmCollectionSyncStatusItem?>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

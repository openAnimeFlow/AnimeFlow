// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(downloadRepository)
final downloadRepositoryProvider = DownloadRepositoryProvider._();

final class DownloadRepositoryProvider extends $FunctionalProvider<
    IDownloadRepository,
    IDownloadRepository,
    IDownloadRepository> with $Provider<IDownloadRepository> {
  DownloadRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'downloadRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$downloadRepositoryHash();

  @$internal
  @override
  $ProviderElement<IDownloadRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IDownloadRepository create(Ref ref) {
    return downloadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IDownloadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IDownloadRepository>(value),
    );
  }
}

String _$downloadRepositoryHash() =>
    r'4182d281170f49a4a5052444a5ed186a4219661b';

@ProviderFor(downloadManager)
final downloadManagerProvider = DownloadManagerProvider._();

final class DownloadManagerProvider extends $FunctionalProvider<
    IDownloadManager,
    IDownloadManager,
    IDownloadManager> with $Provider<IDownloadManager> {
  DownloadManagerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'downloadManagerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$downloadManagerHash();

  @$internal
  @override
  $ProviderElement<IDownloadManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IDownloadManager create(Ref ref) {
    return downloadManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IDownloadManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IDownloadManager>(value),
    );
  }
}

String _$downloadManagerHash() => r'243775f960e4a600e4a606cd268e102790b1c10e';

@ProviderFor(videoSourceResolverPool)
final videoSourceResolverPoolProvider = VideoSourceResolverPoolProvider._();

final class VideoSourceResolverPoolProvider extends $FunctionalProvider<
    IVideoSourceResolverPool,
    IVideoSourceResolverPool,
    IVideoSourceResolverPool> with $Provider<IVideoSourceResolverPool> {
  VideoSourceResolverPoolProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'videoSourceResolverPoolProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$videoSourceResolverPoolHash();

  @$internal
  @override
  $ProviderElement<IVideoSourceResolverPool> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IVideoSourceResolverPool create(Ref ref) {
    return videoSourceResolverPool(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IVideoSourceResolverPool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IVideoSourceResolverPool>(value),
    );
  }
}

String _$videoSourceResolverPoolHash() =>
    r'63e2bc7050b31ddf14e95bf4a492b1d2731133ae';

@ProviderFor(DownloadController)
final downloadControllerProvider = DownloadControllerProvider._();

final class DownloadControllerProvider
    extends $NotifierProvider<DownloadController, DownloadState> {
  DownloadControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'downloadControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$downloadControllerHash();

  @$internal
  @override
  DownloadController create() => DownloadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadState>(value),
    );
  }
}

String _$downloadControllerHash() =>
    r'75c0150e01437b08cf81962bf6888788f5c4d1b7';

abstract class _$DownloadController extends $Notifier<DownloadState> {
  DownloadState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DownloadState, DownloadState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<DownloadState, DownloadState>,
        DownloadState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

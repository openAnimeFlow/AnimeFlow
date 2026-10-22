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

String _$downloadManagerHash() => r'df104043a75b14308bc4ce300205e54e8368e1ef';

@ProviderFor(downloadDanmakuService)
final downloadDanmakuServiceProvider = DownloadDanmakuServiceProvider._();

final class DownloadDanmakuServiceProvider extends $FunctionalProvider<
    IDownloadDanmakuService,
    IDownloadDanmakuService,
    IDownloadDanmakuService> with $Provider<IDownloadDanmakuService> {
  DownloadDanmakuServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'downloadDanmakuServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$downloadDanmakuServiceHash();

  @$internal
  @override
  $ProviderElement<IDownloadDanmakuService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IDownloadDanmakuService create(Ref ref) {
    return downloadDanmakuService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IDownloadDanmakuService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IDownloadDanmakuService>(value),
    );
  }
}

String _$downloadDanmakuServiceHash() =>
    r'ab5b80675f497f155919c2f986fac1763b3d1106';

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
    r'4f59afa10ea0192bad3387b6f1eb6f40c0e93acc';

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
    r'9e670316af204b563d1e59e34f601d4e86e81600';

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

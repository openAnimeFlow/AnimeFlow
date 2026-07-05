// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_source_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VideoSourceController)
final videoSourceControllerProvider = VideoSourceControllerProvider._();

final class VideoSourceControllerProvider
    extends $NotifierProvider<VideoSourceController, VideoSourceState> {
  VideoSourceControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'videoSourceControllerProvider',
          isAutoDispose: false,
          dependencies: <ProviderOrFamily>[
            episodesProvider,
            playExtraProvider,
            playStateProvider,
            playSessionProvider
          ],
          $allTransitiveDependencies: <ProviderOrFamily>{
            VideoSourceControllerProvider.$allTransitiveDependencies0,
            VideoSourceControllerProvider.$allTransitiveDependencies1,
            VideoSourceControllerProvider.$allTransitiveDependencies2,
            VideoSourceControllerProvider.$allTransitiveDependencies3,
            VideoSourceControllerProvider.$allTransitiveDependencies4,
            VideoSourceControllerProvider.$allTransitiveDependencies5,
          },
        );

  static final $allTransitiveDependencies0 = episodesProvider;
  static final $allTransitiveDependencies1 =
      EpisodesProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = playStateProvider;
  static final $allTransitiveDependencies3 = playSessionProvider;
  static final $allTransitiveDependencies4 =
      PlaySessionProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies5 =
      PlaySessionProvider.$allTransitiveDependencies3;

  @override
  String debugGetCreateSourceHash() => _$videoSourceControllerHash();

  @$internal
  @override
  VideoSourceController create() => VideoSourceController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoSourceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoSourceState>(value),
    );
  }
}

String _$videoSourceControllerHash() =>
    r'e92a2a812f68cb26635416a8cf58c714a9f1d07b';

abstract class _$VideoSourceController extends $Notifier<VideoSourceState> {
  VideoSourceState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VideoSourceState, VideoSourceState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<VideoSourceState, VideoSourceState>,
        VideoSourceState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

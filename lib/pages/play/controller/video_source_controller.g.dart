// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_source_controller.dart';

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
          dependencies: <ProviderOrFamily>[episodesProvider, playExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            VideoSourceControllerProvider.$allTransitiveDependencies0,
            VideoSourceControllerProvider.$allTransitiveDependencies1,
          ],
        );

  static final $allTransitiveDependencies0 = episodesProvider;
  static final $allTransitiveDependencies1 =
      EpisodesProvider.$allTransitiveDependencies0;

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
    r'3944b193270aa8193075e76629b3fa9a7de257b4';

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

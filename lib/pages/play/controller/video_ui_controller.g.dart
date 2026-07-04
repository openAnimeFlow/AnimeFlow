// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_ui_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VideoUiStateController)
final videoUiStateControllerProvider = VideoUiStateControllerProvider._();

final class VideoUiStateControllerProvider
    extends $NotifierProvider<VideoUiStateController, VideoUiState> {
  VideoUiStateControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'videoUiStateControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$videoUiStateControllerHash();

  @$internal
  @override
  VideoUiStateController create() => VideoUiStateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoUiState>(value),
    );
  }
}

String _$videoUiStateControllerHash() =>
    r'3820734743504ee62c439af3a1fac721d6b9588d';

abstract class _$VideoUiStateController extends $Notifier<VideoUiState> {
  VideoUiState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VideoUiState, VideoUiState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<VideoUiState, VideoUiState>,
        VideoUiState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

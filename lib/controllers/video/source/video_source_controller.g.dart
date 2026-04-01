// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_source_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 数据源爬取、选源与 WebView 解析；依赖 [EpisodesState]、[PlaySubjectState]（仍为 GetX，在播放页注册）。

@ProviderFor(VideoSourceController)
final videoSourceControllerProvider = VideoSourceControllerProvider._();

/// 数据源爬取、选源与 WebView 解析；依赖 [EpisodesState]、[PlaySubjectState]（仍为 GetX，在播放页注册）。
final class VideoSourceControllerProvider
    extends $NotifierProvider<VideoSourceController, VideoSourceState> {
  /// 数据源爬取、选源与 WebView 解析；依赖 [EpisodesState]、[PlaySubjectState]（仍为 GetX，在播放页注册）。
  VideoSourceControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'videoSourceControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

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
    r'3d494afd1f86e007aa0c0fed3c94a5f45391ca7a';

/// 数据源爬取、选源与 WebView 解析；依赖 [EpisodesState]、[PlaySubjectState]（仍为 GetX，在播放页注册）。

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

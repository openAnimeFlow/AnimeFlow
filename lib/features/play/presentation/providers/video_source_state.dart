import 'package:anime_flow/features/play/domain/selected_video_source.dart';
import 'package:anime_flow/shared/models/player/play/video/resources_item.dart';

class VideoSourceState {
  const VideoSourceState({
    this.videoResources = const [],
    this.selectedSource,
    this.keyword = '',
    this.isSearchCompleted = false,
    this.selectedWebsiteIndex = 0,
    this.userManuallySelected = false,
    this.manualEpisodeSources = const {},
  });

  static const Object _unset = Object();

  final List<ResourcesItem> videoResources;
  final SelectedVideoSource? selectedSource;
  final String keyword;
  final bool isSearchCompleted;

  /// 界面正在浏览的站点，可以与 selectedSource 的播放站点不同。
  final int selectedWebsiteIndex;
  final bool userManuallySelected;
  final Map<int, SelectedVideoSource> manualEpisodeSources;

  String get webSiteTitle => selectedSource?.websiteName ?? '';
  String get webSiteIcon => selectedSource?.websiteIcon ?? '';
  String get resourceTitle => selectedSource?.resourceTitle ?? '';
  String get lineName => selectedSource?.lineName ?? '';
  String get videoUrl => selectedSource?.videoUrl ?? '';

  VideoSourceState copyWith({
    List<ResourcesItem>? videoResources,
    Object? selectedSource = _unset,
    String? keyword,
    bool? isSearchCompleted,
    int? selectedWebsiteIndex,
    bool? userManuallySelected,
    Map<int, SelectedVideoSource>? manualEpisodeSources,
  }) {
    return VideoSourceState(
      videoResources: videoResources ?? this.videoResources,
      selectedSource: identical(selectedSource, _unset)
          ? this.selectedSource
          : selectedSource as SelectedVideoSource?,
      keyword: keyword ?? this.keyword,
      isSearchCompleted: isSearchCompleted ?? this.isSearchCompleted,
      selectedWebsiteIndex: selectedWebsiteIndex ?? this.selectedWebsiteIndex,
      userManuallySelected: userManuallySelected ?? this.userManuallySelected,
      manualEpisodeSources: manualEpisodeSources ?? this.manualEpisodeSources,
    );
  }
}

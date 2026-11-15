import 'package:anime_flow/core/video_source/domain/selected_video_source.dart';
import 'package:anime_flow/features/play/domain/play_source_selection.dart';
import 'package:anime_flow/shared/models/player/play/video/resources_item.dart';

class VideoSourceState {
  const VideoSourceState({
    this.videoResources = const [],
    this.selectedPlaybackSource,
    this.keyword = '',
    this.manualSearchDraft,
    this.isSearchCompleted = false,
    this.selectedWebsiteIndex = 0,
    this.userManuallySelected = false,
    this.manualEpisodeSources = const {},
  });

  static const Object _unset = Object();

  final List<ResourcesItem> videoResources;
  final PlaySourceSelection? selectedPlaybackSource;
  SelectedVideoSource? get selectedSource => switch (selectedPlaybackSource) {
        OnlineEpisodeSource(:final selection) => selection,
        _ => null,
      };
  bool get hasSelectedSource => selectedPlaybackSource != null;
  final String keyword;

  /// 手动搜索框的输入草稿；null 表示尚未编辑。
  final String? manualSearchDraft;
  final bool isSearchCompleted;

  /// 界面正在浏览的站点，可以与 selectedSource 的播放站点不同。
  final int selectedWebsiteIndex;
  final bool userManuallySelected;
  final Map<int, PlaySourceSelection> manualEpisodeSources;

  String get webSiteTitle => selectedSource?.websiteName ?? '';

  VideoSourceState copyWith({
    List<ResourcesItem>? videoResources,
    Object? selectedPlaybackSource = _unset,
    String? keyword,
    String? manualSearchDraft,
    bool? isSearchCompleted,
    int? selectedWebsiteIndex,
    bool? userManuallySelected,
    Map<int, PlaySourceSelection>? manualEpisodeSources,
  }) {
    return VideoSourceState(
      videoResources: videoResources ?? this.videoResources,
      selectedPlaybackSource: identical(selectedPlaybackSource, _unset)
          ? this.selectedPlaybackSource
          : selectedPlaybackSource as PlaySourceSelection?,
      keyword: keyword ?? this.keyword,
      manualSearchDraft: manualSearchDraft ?? this.manualSearchDraft,
      isSearchCompleted: isSearchCompleted ?? this.isSearchCompleted,
      selectedWebsiteIndex: selectedWebsiteIndex ?? this.selectedWebsiteIndex,
      userManuallySelected: userManuallySelected ?? this.userManuallySelected,
      manualEpisodeSources: manualEpisodeSources ?? this.manualEpisodeSources,
    );
  }
}

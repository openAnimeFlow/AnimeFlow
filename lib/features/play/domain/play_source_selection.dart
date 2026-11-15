import 'package:anime_flow/core/video_source/domain/selected_video_source.dart';

/// 用户选择的播放来源，在线剧集页面需要先解析，本地文件可直接打开。
sealed class PlaySourceSelection {
  const PlaySourceSelection();
}

final class OnlineEpisodeSource extends PlaySourceSelection {
  const OnlineEpisodeSource(this.selection);

  final SelectedVideoSource selection;
}

final class LocalVideoFile extends PlaySourceSelection {
  const LocalVideoFile({required this.path, required this.name});

  final String path;
  final String name;
}
